import Foundation
import CoreLocation

public extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.skyscan.app") ?? UserDefaults.standard

    private enum Keys {
        static let lastLatitude = "lastLatitude"
        static let lastLongitude = "lastLongitude"
        static let searchRadiusMiles = "searchRadiusMiles"
        static let cachedFlights = "cachedFlights"
        static let lastFetchTimestamp = "lastFetchTimestamp"
        static let customCityName = "customCityName"
    }

    var lastUserLocation: CLLocationCoordinate2D? {
        get {
            let lat = double(forKey: Keys.lastLatitude)
            let lon = double(forKey: Keys.lastLongitude)
            if lat != 0.0 || lon != 0.0 {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return nil
        }
        set {
            if let coords = newValue {
                set(coords.latitude, forKey: Keys.lastLatitude)
                set(coords.longitude, forKey: Keys.lastLongitude)
            } else {
                removeObject(forKey: Keys.lastLatitude)
                removeObject(forKey: Keys.lastLongitude)
            }
        }
    }

    var searchRadiusMiles: Double {
        get {
            let val = double(forKey: Keys.searchRadiusMiles)
            return val > 0 ? val : 25.0 // default 25 miles
        }
        set {
            set(newValue, forKey: Keys.searchRadiusMiles)
        }
    }

    var cachedFlights: [Flight] {
        get {
            guard let data = data(forKey: Keys.cachedFlights),
                  let flights = try? JSONDecoder().decode([Flight].self, from: data) else {
                return []
            }
            return flights
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.cachedFlights)
                set(Date().timeIntervalSince1970, forKey: Keys.lastFetchTimestamp)
            }
        }
    }

    var lastFetchDate: Date? {
        let ts = double(forKey: Keys.lastFetchTimestamp)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }
}
