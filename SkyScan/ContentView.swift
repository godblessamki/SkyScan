import SwiftUI
import CoreLocation
import WidgetKit

public struct ContentView: View {
    @StateObject private var locationManager = LocationManager.shared
    @AppStorage("searchRadiusMiles", store: UserDefaults.appGroup) private var searchRadius: Double = 25.0
    @AppStorage("isDemoMode") private var isDemoMode: Bool = false

    @State private var flights: [Flight] = []
    @State private var isLoading: Bool = false
    @State private var selectedFlight: Flight?
    @State private var showingSettings: Bool = false
    @State private var viewMode: ViewMode = .radar
    @State private var errorMessage: String?

    enum ViewMode: String, CaseIterable {
        case radar = "Radar"
        case list = "Flight List"
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Airspace Status Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(flights.isEmpty ? Color.gray : Color.green)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: flights.isEmpty ? .clear : .green, radius: 4)

                                Text(statusHeader)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }

                            if let loc = locationManager.currentLocation {
                                Text(String(format: "%.3f°, %.3f° • Range %.0f mi", loc.latitude, loc.longitude, searchRadius))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // View mode picker
                        Picker("View", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))

                    // Content Area
                    if isLoading && flights.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.cyan)
                            Text("Scanning overhead sky...")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if flights.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "airplane.circle")
                                .font(.system(size: 54))
                                .foregroundStyle(.cyan.opacity(0.6))

                            Text("No Planes Overhead")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)

                            Text("There are no aircraft detected within \(Int(searchRadius)) miles of your location right now.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Button {
                                isDemoMode = true
                                fetchFlights()
                            } label: {
                                Label("Simulate Active Airspace", systemImage: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.cyan.opacity(0.2)))
                                    .foregroundStyle(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        switch viewMode {
                        case .radar:
                            VStack(spacing: 0) {
                                RadarView(
                                    flights: flights,
                                    centerLocation: locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790),
                                    radiusMiles: searchRadius,
                                    selectedFlight: $selectedFlight
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                                // Bottom summary card of selected or closest flight
                                if let flight = selectedFlight ?? flights.first {
                                    Button {
                                        selectedFlight = flight
                                    } label: {
                                        FlightRowCard(flight: flight)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                    .padding(.bottom, 12)
                                }
                            }

                        case .list:
                            List {
                                ForEach(flights) { flight in
                                    Button {
                                        selectedFlight = flight
                                    } label: {
                                        FlightRowCard(flight: flight)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                await fetchFlightsAsync()
                            }
                        }
                    }
                }
            }
            .navigationTitle("SKYSCAN")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            fetchFlights()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.cyan)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }
            .sheet(item: $selectedFlight) { flight in
                FlightDetailSheet(flight: flight)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(locationManager: locationManager)
            }
            .onAppear {
                locationManager.requestLocation()
                fetchFlights()
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 15_000_000_000)
                    await fetchFlightsAsync()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statusHeader: String {
        if flights.isEmpty {
            return "NO TRAFFIC"
        } else {
            return "\(flights.count) AIRCRAFT TRACKED"
        }
    }

    private func fetchFlights() {
        Task {
            await fetchFlightsAsync()
        }
    }

    private func fetchFlightsAsync() async {
        guard let location = locationManager.currentLocation else { return }
        isLoading = true
        errorMessage = nil

        if isDemoMode {
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.flights = Flight.sampleList
            self.isLoading = false
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        do {
            let fetched = try await OpenSkyService.shared.fetchOverheadFlights(center: location, radiusMiles: searchRadius)
            self.flights = fetched
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            self.errorMessage = error.localizedDescription
            self.flights = UserDefaults.appGroup.cachedFlights
        }
        self.isLoading = false
    }
}

// MARK: - Flight Row Card
struct FlightRowCard: View {
    let flight: Flight

    var body: some View {
        HStack(spacing: 12) {
            // Airline Logo
            AirlineLogoView(logoData: flight.airlineLogoData, fallbackText: flight.callsign, size: 38, isCommercial: flight.isCommercial)

            // Flight info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(flight.flightNumber ?? flight.callsign)
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)

                    if let route = flight.routeString {
                        Text(route)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }

                    if flight.isDirectlyOverhead {
                        Text("OVERHEAD")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }
                }

                HStack(spacing: 4) {
                    Text(flight.airlineName ?? flight.originCountry)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    if let model = flight.aircraftModel {
                        Text("• \(model)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Altitude & Distance
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Text(flight.altitudeFeet.map { "\($0.formatted())" } ?? "--")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("ft")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Image(systemName: flight.climbState.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(flight.climbState == .climbing ? .green : (flight.climbState == .descending ? .orange : .secondary))
                }

                Text(String(format: "%.1f mi %@", flight.distanceMiles, flight.compassDirection))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.cyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(flight.isDirectlyOverhead ? Color.green.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
