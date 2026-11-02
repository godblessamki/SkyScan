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

    public static let sampleList = [sampleOverhead, sampleNearby]
}
