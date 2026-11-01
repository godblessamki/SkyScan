import Foundation

public struct AirlineInfo: Codable, Hashable, Sendable {
    public let name: String
    public let iata: String
    public let icao: String

    public var logoUrl: URL? {
        URL(string: "https://content.r9cdn.net/rimg/provider-logos/airlines/v/\(iata).png")
    }

    public init(name: String, iata: String, icao: String) {
        self.name = name
        self.iata = iata
        self.icao = icao
    }
}

public struct AirlineDatabase {
    public static let shared = AirlineDatabase()

    private let airlines: [String: AirlineInfo] = [
        // US Major & Regional
        "UAL": AirlineInfo(name: "United Airlines", iata: "UA", icao: "UAL"),
        "AAL": AirlineInfo(name: "American Airlines", iata: "AA", icao: "AAL"),
        "DAL": AirlineInfo(name: "Delta Air Lines", iata: "DL", icao: "DAL"),
        "SWA": AirlineInfo(name: "Southwest Airlines", iata: "WN", icao: "SWA"),
        "ASA": AirlineInfo(name: "Alaska Airlines", iata: "AS", icao: "ASA"),
        "JBU": AirlineInfo(name: "JetBlue Airways", iata: "B6", icao: "JBU"),
        "FFT": AirlineInfo(name: "Frontier Airlines", iata: "F9", icao: "FFT"),
        "NKS": AirlineInfo(name: "Spirit Airlines", iata: "NK", icao: "NKS"),
        "SKW": AirlineInfo(name: "SkyWest Airlines", iata: "OO", icao: "SKW"),
        "ENY": AirlineInfo(name: "Envoy Air", iata: "MQ", icao: "ENY"),
        "RPA": AirlineInfo(name: "Republic Airways", iata: "YX", icao: "RPA"),
        "EDV": AirlineInfo(name: "Endeavor Air", iata: "9E", icao: "EDV"),
        "PSA": AirlineInfo(name: "PSA Airlines", iata: "OH", icao: "PSA"),
        "HAL": AirlineInfo(name: "Hawaiian Airlines", iata: "HA", icao: "HAL"),
        "MXY": AirlineInfo(name: "Breeze Airways", iata: "MX", icao: "MXY"),
        "AAY": AirlineInfo(name: "Allegiant Air", iata: "G4", icao: "AAY"),

        // Cargo
        "FDX": AirlineInfo(name: "FedEx Express", iata: "FX", icao: "FDX"),
        "UPS": AirlineInfo(name: "UPS Airlines", iata: "5X", icao: "UPS"),
        "GTI": AirlineInfo(name: "Atlas Air", iata: "5Y", icao: "GTI"),

        // Europe
        "BAW": AirlineInfo(name: "British Airways", iata: "BA", icao: "BAW"),
        "DLH": AirlineInfo(name: "Lufthansa", iata: "LH", icao: "DLH"),
        "AFR": AirlineInfo(name: "Air France", iata: "AF", icao: "AFR"),
        "KLM": AirlineInfo(name: "KLM Royal Dutch", iata: "KL", icao: "KLM"),
        "IBE": AirlineInfo(name: "Iberia", iata: "IB", icao: "IBE"),
        "RYR": AirlineInfo(name: "Ryanair", iata: "FR", icao: "RYR"),
        "EZY": AirlineInfo(name: "easyJet", iata: "U2", icao: "EZY"),
        "WZZ": AirlineInfo(name: "Wizz Air", iata: "W6", icao: "WZZ"),
        "SWR": AirlineInfo(name: "Swiss International", iata: "LX", icao: "SWR"),
        "AUA": AirlineInfo(name: "Austrian Airlines", iata: "OS", icao: "AUA"),
        "SAS": AirlineInfo(name: "Scandinavian Airlines", iata: "SK", icao: "SAS"),
        "EIN": AirlineInfo(name: "Aer Lingus", iata: "EI", icao: "EIN"),
        "TAP": AirlineInfo(name: "TAP Air Portugal", iata: "TP", icao: "TAP"),
        "AZA": AirlineInfo(name: "ITA Airways", iata: "AZ", icao: "AZA"),
        "ITY": AirlineInfo(name: "ITA Airways", iata: "AZ", icao: "ITY"),
        "FIN": AirlineInfo(name: "Finnair", iata: "AY", icao: "FIN"),
        "THY": AirlineInfo(name: "Turkish Airlines", iata: "TK", icao: "THY"),
        "VIR": AirlineInfo(name: "Virgin Atlantic", iata: "VS", icao: "VIR"),

        // Middle East & Africa
        "UAE": AirlineInfo(name: "Emirates", iata: "EK", icao: "UAE"),
        "QTR": AirlineInfo(name: "Qatar Airways", iata: "QR", icao: "QTR"),
        "ETD": AirlineInfo(name: "Etihad Airways", iata: "EY", icao: "ETD"),
        "SVA": AirlineInfo(name: "Saudia", iata: "SV", icao: "SVA"),
        "ETH": AirlineInfo(name: "Ethiopian Airlines", iata: "ET", icao: "ETH"),

        // Asia / Pacific
        "ANA": AirlineInfo(name: "All Nippon Airways", iata: "NH", icao: "ANA"),
        "JAL": AirlineInfo(name: "Japan Airlines", iata: "JL", icao: "JAL"),
        "SIA": AirlineInfo(name: "Singapore Airlines", iata: "SQ", icao: "SIA"),
        "CPA": AirlineInfo(name: "Cathay Pacific", iata: "CX", icao: "CPA"),
        "KAL": AirlineInfo(name: "Korean Air", iata: "KE", icao: "KAL"),
        "AAR": AirlineInfo(name: "Asiana Airlines", iata: "OZ", icao: "AAR"),
        "QFA": AirlineInfo(name: "Qantas", iata: "QF", icao: "QFA"),
        "ANZ": AirlineInfo(name: "Air New Zealand", iata: "NZ", icao: "ANZ"),
        "VOZ": AirlineInfo(name: "Virgin Australia", iata: "VA", icao: "VOZ"),
        "CCA": AirlineInfo(name: "Air China", iata: "CA", icao: "CCA"),
        "CES": AirlineInfo(name: "China Eastern", iata: "MU", icao: "CES"),
        "CSN": AirlineInfo(name: "China Southern", iata: "CZ", icao: "CSN"),
        "EVA": AirlineInfo(name: "EVA Air", iata: "BR", icao: "EVA"),
        "CAL": AirlineInfo(name: "China Airlines", iata: "CI", icao: "CAL"),
        "AIC": AirlineInfo(name: "Air India", iata: "AI", icao: "AIC"),

        // Americas (Canada / Latin America)
        "ACA": AirlineInfo(name: "Air Canada", iata: "AC", icao: "ACA"),
        "WJA": AirlineInfo(name: "WestJet", iata: "WS", icao: "WJA"),
        "AMX": AirlineInfo(name: "Aeroméxico", iata: "AM", icao: "AMX"),
        "LAN": AirlineInfo(name: "LATAM Airlines", iata: "LA", icao: "LAN"),
        "LPE": AirlineInfo(name: "LATAM Peru", iata: "LP", icao: "LPE"),
        "TAM": AirlineInfo(name: "LATAM Brasil", iata: "JJ", icao: "TAM"),
        "AVA": AirlineInfo(name: "Avianca", iata: "AV", icao: "AVA"),
        "CMP": AirlineInfo(name: "Copa Airlines", iata: "CM", icao: "CMP")
    ]

    // Common airport code mappings (ICAO -> IATA)
    private let airports: [String: (iata: String, city: String)] = [
        "KSFO": ("SFO", "San Francisco"),
        "KJFK": ("JFK", "New York"),
        "KEWR": ("EWR", "Newark"),
        "KLGA": ("LGA", "New York"),
        "KLAX": ("LAX", "Los Angeles"),
        "KORD": ("ORD", "Chicago"),
        "KATL": ("ATL", "Atlanta"),
        "KDFW": ("DFW", "Dallas"),
        "KDEN": ("DEN", "Denver"),
        "KSEA": ("SEA", "Seattle"),
        "KBOS": ("BOS", "Boston"),
        "KMIA": ("MIA", "Miami"),
        "KMCO": ("MCO", "Orlando"),
        "KLAS": ("LAS", "Las Vegas"),
        "KPHX": ("PHX", "Phoenix"),
        "KIAH": ("IAH", "Houston"),
        "KSAN": ("SAN", "San Diego"),
        "KPDX": ("PDX", "Portland"),
        "EGLL": ("LHR", "London"),
        "EGKK": ("LGW", "London"),
        "LFPG": ("CDG", "Paris"),
        "EDDF": ("FRA", "Frankfurt"),
        "EDDM": ("MUC", "Munich"),
        "EHAM": ("AMS", "Amsterdam"),
        "LEMD": ("MAD", "Madrid"),
        "LEBL": ("BCN", "Barcelona"),
        "LIRF": ("FCO", "Rome"),
        "LOWW": ("VIE", "Vienna"),
        "LSZH": ("ZRH", "Zurich"),
        "EIDW": ("DUB", "Dublin"),
        "EBBR": ("BRU", "Brussels"),
        "EKCH": ("CPH", "Copenhagen"),
        "ENGM": ("OSL", "Oslo"),
        "ESSA": ("ARN", "Stockholm"),
        "EFHK": ("HEL", "Helsinki"),
        "LTFM": ("IST", "Istanbul"),
        "OMDB": ("DXB", "Dubai"),
        "OTHH": ("DOH", "Doha"),
        "RJTT": ("HND", "Tokyo"),
        "RJAA": ("NRT", "Tokyo"),
        "RJBB": ("KIX", "Osaka"),
        "RKSI": ("ICN", "Seoul"),
        "VHHH": ("HKG", "Hong Kong"),
        "WSSS": ("SIN", "Singapore"),
        "VTBS": ("BKK", "Bangkok"),
        "YSSY": ("SYD", "Sydney"),
        "YMML": ("MEL", "Melbourne"),
        "CYYZ": ("YYZ", "Toronto"),
        "CYVR": ("YVR", "Vancouver")
    ]

    public func parseCallsign(_ callsign: String) -> (airline: AirlineInfo?, flightNumber: String) {
        let trimmed = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Check 3-letter ICAO code prefix
        if trimmed.count >= 3 {
            let prefix = String(trimmed.prefix(3))
            let suffix = String(trimmed.dropFirst(3)).trimmingCharacters(in: .letters.inverted.inverted)

            if let airline = airlines[prefix] {
                let formattedNumber = suffix.isEmpty ? trimmed : "\(airline.iata) \(suffix)"
                return (airline, formattedNumber)
            }
        }

        return (nil, trimmed)
    }

    public func formatRoute(_ routeCode: String) -> (origin: String, destination: String, display: String)? {
        let parts = routeCode.split(separator: "-").map(String.init)
        guard parts.count == 2 else { return nil }

        let originRaw = parts[0]
        let destRaw = parts[1]

        let originIata = airports[originRaw]?.iata ?? (originRaw.hasPrefix("K") && originRaw.count == 4 ? String(originRaw.dropFirst()) : originRaw)
        let destIata = airports[destRaw]?.iata ?? (destRaw.hasPrefix("K") && destRaw.count == 4 ? String(destRaw.dropFirst()) : destRaw)

        return (originIata, destIata, "\(originIata) ➔ \(destIata)")
    }
}
