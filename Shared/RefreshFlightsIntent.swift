import Foundation
import AppIntents
import WidgetKit
import CoreLocation

public struct RefreshFlightsIntent: AppIntent {
    public static var title: LocalizedStringResource = "Scan Overhead Sky"
    public static var description = IntentDescription("Scans the sky for aircraft currently flying overhead.")

    public init() {}

    public func perform() async throws -> some IntentResult {
        let center = UserDefaults.appGroup.lastUserLocation ?? CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)
        let radius = UserDefaults.appGroup.searchRadiusMiles

        _ = try? await OpenSkyService.shared.fetchOverheadFlights(center: center, radiusMiles: radius)
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
