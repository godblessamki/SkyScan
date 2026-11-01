import Foundation
import CoreLocation

public actor OpenSkyService {
    public static let shared = OpenSkyService()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches overhead flights for a given center coordinate within a radius (in miles)
    public func fetchOverheadFlights(
        center: CLLocationCoordinate2D,
        radiusMiles: Double = 25.0
    ) async throws -> [Flight] {
        let radiusKm = radiusMiles * 1.60934

        // 1 degree latitude ~ 111.0 km
        let latDelta = radiusKm / 111.0
        // 1 degree longitude ~ 111.0 * cos(lat) km
        let latRad = center.latitude * .pi / 180.0
        let lonFactor = max(cos(latRad), 0.01)
        let lonDelta = radiusKm / (111.0 * lonFactor)

        let lamin = center.latitude - latDelta
        let lamax = center.latitude + latDelta
        let lomin = center.longitude - lonDelta
        let lomax = center.longitude + lonDelta

        var components = URLComponents(string: "https://opensky-network.org/api/states/all")!
        components.queryItems = [
            URLQueryItem(name: "lamin", value: String(format: "%.4f", lamin)),
            URLQueryItem(name: "lamax", value: String(format: "%.4f", lamax)),
            URLQueryItem(name: "lomin", value: String(format: "%.4f", lomin)),
            URLQueryItem(name: "lomax", value: String(format: "%.4f", lomax))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        request.setValue("SkyScanApp/1.0 (macOS/iOS Widget; contact: admin@example.com)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 429 {
            // Rate limited: Return cached flights if available
            return UserDefaults.appGroup.cachedFlights
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let states = json["states"] as? [[Any]] else {
            return []
        }

        var rawFlights: [Flight] = []

        for row in states {
            guard row.count >= 11 else { continue }

            let icao24 = (row[0] as? String) ?? ""
            var callsign = (row[1] as? String) ?? ""
            callsign = callsign.trimmingCharacters(in: .whitespacesAndNewlines)
            if callsign.isEmpty {
                callsign = "ICAO: \(icao24.uppercased())"
            }

            let originCountry = (row[2] as? String) ?? "Unknown"

            // Longitude & Latitude
            guard let lon = (row[5] as? NSNumber)?.doubleValue,
                  let lat = (row[6] as? NSNumber)?.doubleValue else {
                continue
            }

            // Exclude planes currently on the ground
            let onGround = (row[8] as? Bool) ?? false
            if onGround {
                continue
            }

            let baroAltitude = (row[7] as? NSNumber)?.doubleValue
            let velocity = (row[9] as? NSNumber)?.doubleValue
            let heading = (row[10] as? NSNumber)?.doubleValue
            let verticalRate = (row[11] as? NSNumber)?.doubleValue

            let flight = Flight(
                id: icao24,
                callsign: callsign,
                originCountry: originCountry,
                latitude: lat,
                longitude: lon,
                altitudeMeters: baroAltitude,
                velocityMps: velocity,
                heading: heading,
                verticalRateMps: verticalRate,
                userLocation: center
            )

            // Only keep flights within the requested radius
            if flight.distanceMiles <= radiusMiles {
                rawFlights.append(flight)
            }
        }

        // Sort closest first
        rawFlights.sort { $0.distanceMiles < $1.distanceMiles }

        // Enrich the top 6 closest flights with metadata, routes & logos
        let topFlights = Array(rawFlights.prefix(6))
        let remainingFlights = Array(rawFlights.dropFirst(6))

        let enrichedTop = await AircraftEnrichmentService.shared.enrichFlights(topFlights)
        let finalFlights = enrichedTop + remainingFlights

        // Cache for widget or offline access
        UserDefaults.appGroup.cachedFlights = finalFlights

        return finalFlights
    }
}
