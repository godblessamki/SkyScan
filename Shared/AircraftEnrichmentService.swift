import Foundation

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

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Enriches a list of flights with aircraft model, registration, route, and airline logo
    public func enrichFlights(_ flights: [Flight]) async -> [Flight] {
        var enriched: [Flight] = []

        for var flight in flights {
            // 1. Enrich Airline Logo
            if flight.airlineLogoData == nil, let iata = flight.airlineIATA {
                flight.airlineLogoData = await fetchLogoData(iata: iata)
            }

            // 2. Enrich Aircraft Type & Registration via hexdb.io
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

            // 3. Enrich Route via hexdb.io
            if flight.routeString == nil && !flight.callsign.isEmpty {
                if let routeCode = await fetchRoute(callsign: flight.callsign) {
                    if let parsed = AirlineDatabase.shared.formatRoute(routeCode) {
                        flight.originAirport = parsed.origin
                        flight.destinationAirport = parsed.destination
                        flight.routeString = parsed.display
                    }
                }
            }

            enriched.append(flight)
        }

        return enriched
    }

    // MARK: - Logo Fetching
    private func fetchLogoData(iata: String) async -> Data? {
        if let cached = logoCache[iata] {
            return cached
        }

        guard let url = URL(string: "https://content.r9cdn.net/rimg/provider-logos/airlines/v/\(iata).png") else {
            return nil
        }

        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 4.0
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                logoCache[iata] = data
                return data
            }
        } catch {
            // Silently fail logo fetch
        }

        return nil
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
