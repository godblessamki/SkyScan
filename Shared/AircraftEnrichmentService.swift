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

        // 1. If commercial flight, fetch airline logo
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

                // If airlineIATA was not matched from callsign, attempt to match from registered owner
                if flight.airlineIATA == nil, let owner = meta.owner, !owner.isEmpty {
                    if let matchedAirline = AirlineDatabase.shared.findAirlineByName(owner) {
                        flight.airlineName = matchedAirline.name
                        flight.airlineIATA = matchedAirline.iata
                        // Fetch logo now that airline IATA is resolved
                        if flight.airlineLogoData == nil {
                            flight.airlineLogoData = await fetchLogoData(iata: matchedAirline.iata)
                        }
                    }
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

    // MARK: - Logo Fetching & Caching (Kiwi Primary + Kayak Fallback + Disk Cache)
    private func fetchLogoData(iata: String) async -> Data? {
        let key = iata.uppercased()
        if let cached = logoCache[key] {
            return cached
        }

        // 1. Check local persistent disk cache first
        if let diskData = loadLogoFromDisk(key: key) {
            logoCache[key] = diskData
            return diskData
        }

        // 2. Candidate CDNs in order of reliability & speed:
        //    a. Kiwi CDN (crisp 64x64 pre-cropped PNGs)
        //    b. Kayak CDN (vector/high-res PNGs)
        let candidates = [
            URL(string: "https://images.kiwi.com/airlines/64x64/\(key).png"),
            URL(string: "https://content.r9cdn.net/rimg/provider-logos/airlines/v/\(key).png")
        ].compactMap { $0 }

        for url in candidates {
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 3.0
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 100 else {
                    continue
                }

                // If image is larger than 120px, optimize to clean 100px thumbnail
                let finalData: Data
                if let resized = resizeImageToThumbnail(data: data, maxPixelSize: 100) {
                    finalData = resized
                } else {
                    finalData = data
                }

                logoCache[key] = finalData
                saveLogoToDisk(key: key, data: finalData)
                return finalData
            } catch {
                continue
            }
        }

        return nil
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

    // MARK: - Disk Cache Helpers
    private var cacheDirectory: URL? {
        let fileManager = FileManager.default
        guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("AirlineLogos", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func loadLogoFromDisk(key: String) -> Data? {
        guard let dir = cacheDirectory else { return nil }
        let file = dir.appendingPathComponent("\(key).png")
        return try? Data(contentsOf: file)
    }

    private func saveLogoToDisk(key: String, data: Data) {
        guard let dir = cacheDirectory else { return }
        let file = dir.appendingPathComponent("\(key).png")
        try? data.write(to: file, options: .atomic)
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
