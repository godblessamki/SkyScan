import Foundation
import CoreLocation

public enum ClimbState: String, Codable, Sendable {
    case climbing = "climbing"
    case descending = "descending"
    case level = "level"

    public var symbol: String {
        switch self {
        case .climbing: return "arrow.up.right"
        case .descending: return "arrow.down.right"
        case .level: return "arrow.right"
        }
    }
}

public struct Flight: Identifiable, Codable, Hashable, Sendable {
    public let id: String // icao24
    public let callsign: String

    // Airline & Commercial Flight Info
    public var airlineName: String?
    public var airlineIATA: String?
    public var flightNumber: String?
    public var aircraftModel: String?
    public var aircraftTypeCode: String?
    public var registration: String?
    public var originAirport: String?
    public var destinationAirport: String?
    public var routeString: String?
    public var airlineLogoData: Data?

    public var isCommercial: Bool {
        airlineIATA != nil
    }

    public let originCountry: String
    public let latitude: Double
    public let longitude: Double
    public let altitudeMeters: Double?
    public let altitudeFeet: Int?
    public let velocityMps: Double?
    public let velocityKnots: Int?
    public let heading: Double? // true track (0-360)
    public let verticalRateMps: Double?
    public let climbState: ClimbState
    public let distanceKm: Double
    public let distanceMiles: Double
    public let bearingDegrees: Double
    public let compassDirection: String
    public let elevationAngle: Double // degrees above horizon
    public let isDirectlyOverhead: Bool
    public let lastUpdated: Date

    public init(
        id: String,
        callsign: String,
        originCountry: String,
        latitude: Double,
        longitude: Double,
        altitudeMeters: Double?,
        velocityMps: Double?,
        heading: Double?,
        verticalRateMps: Double?,
        userLocation: CLLocationCoordinate2D,
        airlineName: String? = nil,
        airlineIATA: String? = nil,
        flightNumber: String? = nil,
        aircraftModel: String? = nil,
        aircraftTypeCode: String? = nil,
        registration: String? = nil,
        originAirport: String? = nil,
        destinationAirport: String? = nil,
        routeString: String? = nil,
        airlineLogoData: Data? = nil
    ) {
        self.id = id
        let cleanCallsign = callsign.trimmingCharacters(in: .whitespacesAndNewlines)
        self.callsign = cleanCallsign
        self.originCountry = originCountry
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.velocityMps = velocityMps
        self.heading = heading
        self.verticalRateMps = verticalRateMps
        self.lastUpdated = Date()

        // Match airline from callsign
        let parsed = AirlineDatabase.shared.parseCallsign(cleanCallsign)
        var resolvedName = airlineName ?? parsed.airline?.name
        var resolvedIata = airlineIATA ?? parsed.airline?.iata
        let resolvedFlightNum = flightNumber ?? parsed.flightNumber

        // If airline still not resolved, try name fallback (e.g. from hexdb owner)
        if resolvedIata == nil, let name = resolvedName {
            if let matched = AirlineDatabase.shared.findAirlineByName(name) {
                resolvedName = matched.name
                resolvedIata = matched.iata
            }
        }

        self.airlineName = resolvedName
        self.airlineIATA = resolvedIata
        self.flightNumber = resolvedFlightNum

        self.aircraftModel = aircraftModel
        self.aircraftTypeCode = aircraftTypeCode
        self.registration = registration
        self.originAirport = originAirport
        self.destinationAirport = destinationAirport
        self.routeString = routeString
        self.airlineLogoData = airlineLogoData

        // Altitude conversions
        if let altM = altitudeMeters {
            self.altitudeFeet = Int(round(altM * 3.28084))
        } else {
            self.altitudeFeet = nil
        }

        // Velocity conversions
        if let velMps = velocityMps {
            self.velocityKnots = Int(round(velMps * 1.94384))
        } else {
            self.velocityKnots = nil
        }

        // Climb state
        if let vr = verticalRateMps {
            if vr > 1.5 {
                self.climbState = .climbing
            } else if vr < -1.5 {
                self.climbState = .descending
            } else {
                self.climbState = .level
            }
        } else {
            self.climbState = .level
        }

        // Haversine ground distance
        let planeLoc = CLLocation(latitude: latitude, longitude: longitude)
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distMeters = userLoc.distance(from: planeLoc)
        self.distanceKm = distMeters / 1000.0
        self.distanceMiles = distMeters / 1609.344

        // Compass bearing
        let bearing = Flight.calculateBearing(from: userLocation, to: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        self.bearingDegrees = bearing
        self.compassDirection = Flight.bearingToCompass(bearing)

        // Elevation angle
        if let altM = altitudeMeters, distMeters > 0 {
            let angleRad = atan2(altM, distMeters)
            self.elevationAngle = angleRad * 180.0 / .pi
        } else {
            self.elevationAngle = 0.0
        }

        self.isDirectlyOverhead = self.elevationAngle >= 35.0 || self.distanceMiles < 3.0
    }

    public static func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180.0
        let lon1 = start.longitude * .pi / 180.0
        let lat2 = end.latitude * .pi / 180.0
        let lon2 = end.longitude * .pi / 180.0

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        var degrees = radians * 180.0 / .pi
        if degrees < 0 {
            degrees += 360.0
        }
        return degrees
    }

    public static func bearingToCompass(_ bearing: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(bearing / 22.5)) % 16
        return directions[index]
    }
}

// MARK: - Sample Preview Data
extension Flight {
    // Pre-bundled high-res 64x64 airline logos for instant rendering in previews and demo mode
    private static let sampleLogoUABase64 = "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"

    private static let sampleLogoDLBase64 = "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"

    public static let sampleOverhead = Flight(
        id: "a12bc3",
        callsign: "UAL1542",
        originCountry: "United States",
        latitude: 37.7749,
        longitude: -122.4194,
        altitudeMeters: 9753.6, // ~32,000 ft
        velocityMps: 231.5,     // ~450 knots
        heading: 75.0,
        verticalRateMps: 0.0,
        userLocation: CLLocationCoordinate2D(latitude: 37.7680, longitude: -122.4200),
        airlineName: "United Airlines",
        airlineIATA: "UA",
        flightNumber: "UA 1542",
        aircraftModel: "Boeing 777-200ER",
        aircraftTypeCode: "B772",
        registration: "N78013",
        originAirport: "SFO",
        destinationAirport: "JFK",
        routeString: "SFO ➔ JFK",
        airlineLogoData: Data(base64Encoded: sampleLogoUABase64)
    )

    public static let sampleNearby = Flight(
        id: "c89ef1",
        callsign: "DAL883",
        originCountry: "United States",
        latitude: 37.8200,
        longitude: -122.3800,
        altitudeMeters: 4572.0, // ~15,000 ft
        velocityMps: 180.0,     // ~350 knots
        heading: 210.0,
        verticalRateMps: -5.2,
        userLocation: CLLocationCoordinate2D(latitude: 37.7680, longitude: -122.4200),
        airlineName: "Delta Air Lines",
        airlineIATA: "DL",
        flightNumber: "DL 883",
        aircraftModel: "Airbus A321neo",
        aircraftTypeCode: "A21N",
        registration: "N523DA",
        originAirport: "SEA",
        destinationAirport: "LAX",
        routeString: "SEA ➔ LAX",
        airlineLogoData: Data(base64Encoded: sampleLogoDLBase64)
    )

    private static let sampleLogoAABase64 = "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"

    public static let sampleThird = Flight(
        id: "d34gh5",
        callsign: "AAL104",
        originCountry: "United States",
        latitude: 37.8500,
        longitude: -122.3500,
        altitudeMeters: 7620.0, // ~25,000 ft
        velocityMps: 210.0,     // ~410 knots
        heading: 85.0,
        verticalRateMps: 2.1,
        userLocation: CLLocationCoordinate2D(latitude: 37.7680, longitude: -122.4200),
        airlineName: "American Airlines",
        airlineIATA: "AA",
        flightNumber: "AA 104",
        aircraftModel: "Boeing 787-9 Dreamliner",
        aircraftTypeCode: "B789",
        registration: "N828AA",
        originAirport: "DFW",
        destinationAirport: "ORD",
        routeString: "DFW ➔ ORD",
        airlineLogoData: Data(base64Encoded: sampleLogoAABase64)
    )

    public static let sampleList = [sampleOverhead, sampleNearby, sampleThird]

}
