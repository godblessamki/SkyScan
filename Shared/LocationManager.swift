import Foundation
import CoreLocation
import Combine

@MainActor
public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()

    @Published public var currentLocation: CLLocationCoordinate2D?
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var isLocating: Bool = false
    @Published public var errorMessage: String?

    private let manager = CLLocationManager()

    public override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.authorizationStatus = manager.authorizationStatus

        // Load cached location if available
        if let cached = UserDefaults.appGroup.lastUserLocation {
            self.currentLocation = cached
        } else {
            // Default fallback: San Francisco International Airport area (high air traffic)
            self.currentLocation = CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)
        }
    }

    public func requestLocation() {
        isLocating = true
        errorMessage = nil

        #if os(iOS)
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "Location permission denied. Using last saved location."
        @unknown default:
            break
        }
        #elseif os(macOS)
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "Location permission denied. Using last saved location."
        @unknown default:
            break
        }
        #endif
    }

    public func setManualLocation(latitude: Double, longitude: Double) {
        let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.currentLocation = coords
        UserDefaults.appGroup.lastUserLocation = coords
    }

    // MARK: - CLLocationManagerDelegate

    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            #if os(iOS)
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
            #elseif os(macOS)
            if status == .authorizedAlways {
                manager.requestLocation()
            }
            #endif
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
            UserDefaults.appGroup.lastUserLocation = location.coordinate
            self.isLocating = false
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.errorMessage = error.localizedDescription
        }
    }
}
