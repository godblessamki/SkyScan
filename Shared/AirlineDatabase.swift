import Foundation

public struct AirlineInfo: Codable, Hashable, Sendable {
    public let name: String
    public let iata: String
    public let icao: String

    public var logoUrl: URL? {
        URL(string: "https://images.kiwi.com/airlines/64x64/\(iata).png")
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
        // US Major Airlines
        "UAL": AirlineInfo(name: "United Airlines", iata: "UA", icao: "UAL"),
        "AAL": AirlineInfo(name: "American Airlines", iata: "AA", icao: "AAL"),
        "DAL": AirlineInfo(name: "Delta Air Lines", iata: "DL", icao: "DAL"),
        "SWA": AirlineInfo(name: "Southwest Airlines", iata: "WN", icao: "SWA"),
        "ASA": AirlineInfo(name: "Alaska Airlines", iata: "AS", icao: "ASA"),
        "JBU": AirlineInfo(name: "JetBlue Airways", iata: "B6", icao: "JBU"),
        "FFT": AirlineInfo(name: "Frontier Airlines", iata: "F9", icao: "FFT"),
        "NKS": AirlineInfo(name: "Spirit Airlines", iata: "NK", icao: "NKS"),
        "HAL": AirlineInfo(name: "Hawaiian Airlines", iata: "HA", icao: "HAL"),
        "AAY": AirlineInfo(name: "Allegiant Air", iata: "G4", icao: "AAY"),
        "MXY": AirlineInfo(name: "Breeze Airways", iata: "MX", icao: "MXY"),
        "SCX": AirlineInfo(name: "Sun Country Airlines", iata: "SY", icao: "SCX"),

        // US Regional / Express Feeders (American Eagle, United Express, Delta Connection)
        "JIA": AirlineInfo(name: "PSA Airlines (American Eagle)", iata: "AA", icao: "JIA"),
        "PSA": AirlineInfo(name: "PSA Airlines (American Eagle)", iata: "AA", icao: "PSA"),
        "PDT": AirlineInfo(name: "Piedmont Airlines (American Eagle)", iata: "AA", icao: "PDT"),
        "ENY": AirlineInfo(name: "Envoy Air (American Eagle)", iata: "AA", icao: "ENY"),
        "EDV": AirlineInfo(name: "Endeavor Air (Delta Connection)", iata: "DL", icao: "EDV"),
        "SKW": AirlineInfo(name: "SkyWest Airlines", iata: "OO", icao: "SKW"),
        "RPA": AirlineInfo(name: "Republic Airways", iata: "YX", icao: "RPA"),
        "ASH": AirlineInfo(name: "Mesa Airlines", iata: "YV", icao: "ASH"),
        "QXE": AirlineInfo(name: "Horizon Air (Alaska)", iata: "QX", icao: "QXE"),
        "GJS": AirlineInfo(name: "GoJet Airlines (United Express)", iata: "G7", icao: "GJS"),
        "UCA": AirlineInfo(name: "CommuteAir (United Express)", iata: "C5", icao: "UCA"),
        "AWI": AirlineInfo(name: "Air Wisconsin (American Eagle)", iata: "ZW", icao: "AWI"),
        "CPZ": AirlineInfo(name: "Compass Airlines", iata: "CP", icao: "CPZ"),
        "SIL": AirlineInfo(name: "Silver Airways", iata: "3M", icao: "SIL"),

        // Cargo
        "FDX": AirlineInfo(name: "FedEx Express", iata: "FX", icao: "FDX"),
        "UPS": AirlineInfo(name: "UPS Airlines", iata: "5X", icao: "UPS"),
        "GTI": AirlineInfo(name: "Atlas Air", iata: "5Y", icao: "GTI"),
        "PAC": AirlineInfo(name: "Polar Air Cargo", iata: "PO", icao: "PAC"),
        "CKS": AirlineInfo(name: "Kalitta Air", iata: "K4", icao: "CKS"),
        "CLX": AirlineInfo(name: "Cargolux", iata: "CV", icao: "CLX"),

        // Canada & Latin America
        "ACA": AirlineInfo(name: "Air Canada", iata: "AC", icao: "ACA"),
        "WJA": AirlineInfo(name: "WestJet", iata: "WS", icao: "WJA"),
        "AMX": AirlineInfo(name: "Aeroméxico", iata: "AM", icao: "AMX"),
        "SLI": AirlineInfo(name: "Aeroméxico Connect", iata: "5D", icao: "SLI"),
        "VIV": AirlineInfo(name: "VivaAeroBus", iata: "VB", icao: "VIV"),
        "VOI": AirlineInfo(name: "Volaris", iata: "Y4", icao: "VOI"),
        "LAN": AirlineInfo(name: "LATAM Airlines", iata: "LA", icao: "LAN"),
        "LPE": AirlineInfo(name: "LATAM Peru", iata: "LP", icao: "LPE"),
        "TAM": AirlineInfo(name: "LATAM Brasil", iata: "JJ", icao: "TAM"),
        "AVA": AirlineInfo(name: "Avianca", iata: "AV", icao: "AVA"),
        "CMP": AirlineInfo(name: "Copa Airlines", iata: "CM", icao: "CMP"),
        "GLO": AirlineInfo(name: "GOL Airlines", iata: "G3", icao: "GLO"),
        "AZU": AirlineInfo(name: "Azul Brazilian", iata: "AD", icao: "AZU"),
        "ARG": AirlineInfo(name: "Aerolíneas Argentinas", iata: "AR", icao: "ARG"),
        "TSC": AirlineInfo(name: "Air Transat", iata: "TS", icao: "TSC"),
        "FLE": AirlineInfo(name: "Flair Airlines", iata: "F8", icao: "FLE"),
        "POE": AirlineInfo(name: "Porter Airlines", iata: "PD", icao: "POE"),

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
        "LOT": AirlineInfo(name: "LOT Polish Airlines", iata: "LO", icao: "LOT"),
        "VLG": AirlineInfo(name: "Vueling", iata: "VY", icao: "VLG"),
        "EWG": AirlineInfo(name: "Eurowings", iata: "EW", icao: "EWG"),
        "ICE": AirlineInfo(name: "Icelandair", iata: "FI", icao: "ICE"),
        "NAX": AirlineInfo(name: "Norwegian Air", iata: "DY", icao: "NAX"),

        // Middle East & Africa
        "UAE": AirlineInfo(name: "Emirates", iata: "EK", icao: "UAE"),
        "QTR": AirlineInfo(name: "Qatar Airways", iata: "QR", icao: "QTR"),
        "ETD": AirlineInfo(name: "Etihad Airways", iata: "EY", icao: "ETD"),
        "SVA": AirlineInfo(name: "Saudia", iata: "SV", icao: "SVA"),
        "ETH": AirlineInfo(name: "Ethiopian Airlines", iata: "ET", icao: "ETH"),
        "FDB": AirlineInfo(name: "flydubai", iata: "FZ", icao: "FDB"),

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
        "IGO": AirlineInfo(name: "IndiGo", iata: "6E", icao: "IGO")
    ]

    // Lookup index by 2-letter IATA code
    private let iataIndex: [String: AirlineInfo]

    public init() {
        var idx: [String: AirlineInfo] = [:]
        for (_, info) in airlines {
            if idx[info.iata] == nil {
                idx[info.iata] = info
            }
        }
        self.iataIndex = idx
    }

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
        "KSAT": ("SAT", "San Antonio"),
        "KAUS": ("AUS", "Austin"),
        "KMSP": ("MSP", "Minneapolis"),
        "KDTW": ("DTW", "Detroit"),
        "KPHL": ("PHL", "Philadelphia"),
        "KCLT": ("CLT", "Charlotte"),
        "KBWI": ("BWI", "Baltimore"),
        "KDCA": ("DCA", "Washington DC"),
        "KIAD": ("IAD", "Washington DC"),
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
        "CYVR": ("YVR", "Vancouver"),
        "MMMX": ("MEX", "Mexico City"),
        "MMUN": ("CUN", "Cancún")
    ]

    public func parseCallsign(_ callsign: String) -> (airline: AirlineInfo?, flightNumber: String) {
        let trimmed = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 1. Check 3-letter ICAO prefix (e.g. UAL1542 -> UAL)
        if trimmed.count >= 3 {
            let prefix3 = String(trimmed.prefix(3))
            let suffix3 = String(trimmed.dropFirst(3)).trimmingCharacters(in: .letters.inverted.inverted)

            if let airline = airlines[prefix3] {
                let formattedNumber = suffix3.isEmpty ? trimmed : "\(airline.iata) \(suffix3)"
                return (airline, formattedNumber)
            }
        }

        // 2. Check 2-letter IATA prefix (e.g. UA1542, DL883, AA1976)
        if trimmed.count >= 2 {
            let prefix2 = String(trimmed.prefix(2))
            let suffix2 = String(trimmed.dropFirst(2)).trimmingCharacters(in: .letters.inverted.inverted)

            if let airline = iataIndex[prefix2] {
                let formattedNumber = suffix2.isEmpty ? trimmed : "\(airline.iata) \(suffix2)"
                return (airline, formattedNumber)
            }
        }

        return (nil, trimmed)
    }

    /// Fuzzy matches an owner or airline name string from hexdb (e.g. "American Airlines", "SkyWest", "United")
    public func findAirlineByName(_ name: String) -> AirlineInfo? {
        let lower = name.lowercased()
        for (_, info) in airlines {
            let infoLower = info.name.lowercased()
            if lower.contains(infoLower) || infoLower.contains(lower) {
                return info
            }
        }
        if lower.contains("american eagle") {
            return airlines["AAL"]
        }
        if lower.contains("united express") {
            return airlines["UAL"]
        }
        if lower.contains("delta connection") {
            return airlines["DAL"]
        }
        return nil
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
