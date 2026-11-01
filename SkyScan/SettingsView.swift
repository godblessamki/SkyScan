import SwiftUI
import CoreLocation
import WidgetKit

public struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("searchRadiusMiles", store: UserDefaults.appGroup) private var searchRadius: Double = 25.0
    @AppStorage("isDemoMode") private var isDemoMode: Bool = false

    @State private var customLat: String = ""
    @State private var customLon: String = ""
    @State private var selectedPresetIndex: Int = 0

    private struct PresetLocation {
        let name: String
        let lat: Double
        let lon: Double
    }

    private let presets: [PresetLocation] = [
        PresetLocation(name: "San Francisco (SFO)", lat: 37.6213, lon: -122.3790),
        PresetLocation(name: "New York (JFK)", lat: 40.6413, lon: -73.7781),
        PresetLocation(name: "London (LHR)", lat: 51.4700, lon: -0.4543),
        PresetLocation(name: "Frankfurt (FRA)", lat: 50.0379, lon: 8.5622),
        PresetLocation(name: "Tokyo (HND)", lat: 35.5494, lon: 139.7798)
    ]

    public var body: some View {
        NavigationStack {
            Form {
                Section("Search Radius") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overhead Airspace Range")
                            Spacer()
                            Text(String(format: "%.0f miles", searchRadius))
                                .fontWeight(.bold)
                                .foregroundStyle(.cyan)
                        }

                        Slider(value: $searchRadius, in: 5...50, step: 5) {
                            Text("Radius")
                        }
                        .tint(.cyan)

                        Text("Detects planes within a \(Int(searchRadius))-mile radius around your coordinates.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Location Source") {
                    Button {
                        locationManager.requestLocation()
                    } label: {
                        HStack {
                            Label("Use My Current GPS Location", systemImage: "location.fill")
                            Spacer()
                            if locationManager.isLocating {
                                ProgressView()
                            }
                        }
                    }

                    if let loc = locationManager.currentLocation {
                        HStack {
                            Text("Active Coordinates")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.4f, %.4f", loc.latitude, loc.longitude))
                                .font(.caption.monospaced())
                                .foregroundStyle(.cyan)
                        }
                    }
                }

                Section("Test Airport Presets") {
                    Picker("Simulate Airport Airspace", selection: $selectedPresetIndex) {
                        ForEach(0..<presets.count, id: \.self) { index in
                            Text(presets[index].name).tag(index)
                        }
                    }
                    .onChange(of: selectedPresetIndex) { _, newIndex in
                        let preset = presets[newIndex]
                        locationManager.setManualLocation(latitude: preset.lat, longitude: preset.lon)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }

                Section("Testing & Simulation") {
                    Toggle("Demo Mode (Simulated Aircraft)", isOn: $isDemoMode)
                        .tint(.cyan)
                    Text("Generates realistic flight data if there are no planes overhead or if testing indoors.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Widget Setup Guide") {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("macOS Desktop & Notification Center", systemImage: "macbook")
                            .font(.subheadline.bold())
                        Text("Right-click your macOS desktop -> Edit Widgets -> Search for 'SkyScan' and drag it onto your screen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider().padding(.vertical, 4)

                        Label("iOS Home & Lock Screen", systemImage: "iphone")
                            .font(.subheadline.bold())
                        Text("Long-press on your iPhone Home Screen -> Tap '+' at the top -> Select 'SkyScan' -> Choose Small, Medium, or Large.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
