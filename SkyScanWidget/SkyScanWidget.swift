import WidgetKit
import SwiftUI
import CoreLocation

public struct FlightEntry: TimelineEntry {
    public let date: Date
    public let flights: [Flight]
    public let closestFlight: Flight?
    public let userLocation: CLLocationCoordinate2D?
    public let isError: Bool

    public init(
        date: Date = Date(),
        flights: [Flight] = [],
        userLocation: CLLocationCoordinate2D? = nil,
        isError: Bool = false
    ) {
        self.date = date
        self.flights = flights
        self.closestFlight = flights.first
        self.userLocation = userLocation
        self.isError = isError
    }
}

public struct SkyScanTimelineProvider: TimelineProvider {
    public typealias Entry = FlightEntry

    public func placeholder(in context: Context) -> FlightEntry {
        FlightEntry(date: Date(), flights: Flight.sampleList)
    }

    public func getSnapshot(in context: Context, completion: @escaping (FlightEntry) -> Void) {
        let cached = UserDefaults.appGroup.cachedFlights
        let flights = cached.isEmpty ? Flight.sampleList : cached
        completion(FlightEntry(date: Date(), flights: flights))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<FlightEntry>) -> Void) {
        let location = UserDefaults.appGroup.lastUserLocation ?? CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)
        let radius = UserDefaults.appGroup.searchRadiusMiles

        Task {
            do {
                let flights = try await OpenSkyService.shared.fetchOverheadFlights(center: location, radiusMiles: radius)
                let entry = FlightEntry(date: Date(), flights: flights, userLocation: location)

                // Schedule next periodic refresh in 15 minutes (widgets are budget-throttled by system)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                // Fall back to cached flights
                let cached = UserDefaults.appGroup.cachedFlights
                let entry = FlightEntry(date: Date(), flights: cached, userLocation: location, isError: true)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date().addingTimeInterval(600)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

public struct SkyScanWidget: Widget {
    public let kind: String = "SkyScanWidget"

    public init() {}

    private var supportedFamiliesList: [WidgetFamily] {
        #if os(iOS)
        return [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular
        ]
        #else
        return [
            .systemSmall,
            .systemMedium,
            .systemLarge
        ]
        #endif
    }

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SkyScanTimelineProvider()) { entry in
            SkyScanWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetRadarBackground()
                }
        }
        .configurationDisplayName("Overhead Flights")
        .description("Track airplanes flying directly above your location in real time.")
        .supportedFamilies(supportedFamiliesList)
    }
}
