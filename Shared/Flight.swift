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
        self.airlineName = airlineName ?? parsed.airline?.name
        self.airlineIATA = airlineIATA ?? parsed.airline?.iata
        self.flightNumber = flightNumber ?? parsed.flightNumber

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
        routeString: "SFO ➔ JFK"
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
        routeString: "SEA ➔ LAX"
    )

    public static let sampleList = [sampleOverhead, sampleNearby]
}
