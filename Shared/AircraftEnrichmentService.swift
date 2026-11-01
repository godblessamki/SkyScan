import Foundation
import CoreGraphics
import ImageIO

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public actor AircraftEnrichmentService {
    public static let shared = AircraftEnrichmentService()

    private var aircraftCache: [String: AircraftMetadata] = [:]
    private var routeCache: [String: String] = [:]
    private var logoCache: [String: Data] = [:]

    private struct AircraftMetadata: Codable {
        let model: String
        let typeCode: String
        let registration: String
        let owner: String?
    }

    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 6.0
        config.httpAdditionalHeaders = [
            "User-Agent": "SkyScan/1.0 (macOS/iOS Widget; contact: admin@example.com)"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Enriches multiple flights concurrently using a TaskGroup
    public func enrichFlights(_ flights: [Flight]) async -> [Flight] {
        await withTaskGroup(of: Flight.self) { group in
            for flight in flights {
                group.addTask {
                    await self.enrichSingleFlight(flight)
                }
            }

            var results: [Flight] = []
            for await enriched in group {
                results.append(enriched)
            }

            // Restore original sort order
            let idOrder = Dictionary(uniqueKeysWithValues: flights.enumerated().map { ($1.id, $0) })
            return results.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
        }
    }

    public func enrichSingleFlight(_ inputFlight: Flight) async -> Flight {
        var flight = inputFlight

        // 1. Fetch Airline Logo (if commercial flight)
        if flight.airlineLogoData == nil, let iata = flight.airlineIATA {
            flight.airlineLogoData = await fetchLogoData(iata: iata)
        }

        // 2. Fetch Aircraft Model & Registration via hexdb.io
        if flight.aircraftModel == nil {
            if let meta = await fetchAircraftMetadata(icao24: flight.id) {
                flight.aircraftModel = meta.model
                flight.aircraftTypeCode = meta.typeCode
                flight.registration = meta.registration
                if flight.airlineName == nil, let owner = meta.owner, !owner.isEmpty {
                    flight.airlineName = owner
                }
            }
        }

        // 3. Fetch Route via hexdb.io
        if flight.routeString == nil && !flight.callsign.isEmpty {
            if let routeCode = await fetchRoute(callsign: flight.callsign) {
                if let parsed = AirlineDatabase.shared.formatRoute(routeCode) {
                    flight.originAirport = parsed.origin
                    flight.destinationAirport = parsed.destination
                    flight.routeString = parsed.display
                }
            }
        }

        return flight
    }

    // MARK: - Logo Fetching & Thumbnail Resizing
    private func fetchLogoData(iata: String) async -> Data? {
        let key = iata.uppercased()
        if let cached = logoCache[key] {
            return cached
        }

        guard let url = URL(string: "https://content.r9cdn.net/rimg/provider-logos/airlines/v/\(key).png") else {
            return nil
        }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 3.0
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            // Optimize & resize image into a clean 100x100 thumbnail for widgets
            if let resizedData = resizeImageToThumbnail(data: data, maxPixelSize: 100) {
                logoCache[key] = resizedData
                return resizedData
            } else {
                logoCache[key] = data
                return data
            }
        } catch {
            return nil
        }
    }

    private func resizeImageToThumbnail(data: Data, maxPixelSize: CGFloat) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        #if os(macOS)
        let rep = NSBitmapImageRep(cgImage: thumb)
        return rep.representation(using: .png, properties: [:])
        #else
        let uiImg = UIImage(cgImage: thumb)
        return uiImg.pngData()
        #endif
    }

    // MARK: - Aircraft Metadata via hexdb.io
    private func fetchAircraftMetadata(icao24: String) async -> AircraftMetadata? {
        let key = icao24.lowercased()
        if let cached = aircraftCache[key] {
            return cached
        }

        guard let url = URL(string: "https://hexdb.io/api/v1/aircraft/\(key)") else {
            return nil
        }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 3.0
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            let manufacturer = (json["Manufacturer"] as? String) ?? ""
            let type = (json["Type"] as? String) ?? ""
            let typeCode = (json["ICAOTypeCode"] as? String) ?? ""
            let registration = (json["Registration"] as? String) ?? ""
            let owner = json["RegisteredOwners"] as? String

            let fullModel = [manufacturer, type].filter { !$0.isEmpty }.joined(separator: " ")
            let meta = AircraftMetadata(
                model: fullModel.isEmpty ? typeCode : fullModel,
                typeCode: typeCode,
                registration: registration,
                owner: owner
            )

            aircraftCache[key] = meta
            return meta
        } catch {
            return nil
        }
    }

    // MARK: - Route Lookup via hexdb.io
    private func fetchRoute(callsign: String) async -> String? {
        let clean = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let cached = routeCache[clean] {
            return cached
        }

        guard let url = URL(string: "https://hexdb.io/api/v1/route/icao/\(clean)") else {
            return nil
        }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 3.0
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let route = json["route"] as? String else {
                return nil
            }

            routeCache[clean] = route
            return route
        } catch {
            return nil
        }
    }
}
