import WidgetKit
import SwiftUI
import AppIntents

public struct SkyScanWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FlightEntry

    public var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        #if os(iOS)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        #endif
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Background View
public struct WidgetRadarBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.02, green: 0.03, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radar grid lines
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let maxRadius = min(geo.size.width, geo.size.height) * 0.75

                Path { path in
                    path.addArc(center: center, radius: maxRadius * 0.33, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    path.addArc(center: center, radius: maxRadius * 0.66, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    path.addArc(center: center, radius: maxRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                }
                .stroke(Color.cyan.opacity(0.08), lineWidth: 1)
            }
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Header with interactive Scan button
            HStack {
                Label("SKYSCAN", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)

                Spacer()

                Button(intent: RefreshFlightsIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if let flight = entry.closestFlight {
                // Airline logo + Flight Number
                HStack(spacing: 5) {
                    AirlineLogoView(logoData: flight.airlineLogoData, fallbackText: flight.callsign, size: 24, isCommercial: flight.isCommercial)

                    Text(flight.flightNumber ?? flight.callsign)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "airplane")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(flight.isDirectlyOverhead ? .green : .cyan)
                        .rotationEffect(.degrees((flight.heading ?? 0) - 90))
                }

                // Route & Aircraft model
                if let route = flight.routeString {
                    Text(route)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .lineLimit(1)
                } else if let model = flight.aircraftModel {
                    Text(model)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Altitude
                if let alt = flight.altitudeFeet {
                    HStack(spacing: 2) {
                        Text("\(alt.formatted())")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("FT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)

                        Image(systemName: flight.climbState.symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(flight.climbState == .climbing ? .green : (flight.climbState == .descending ? .orange : .secondary))
                    }
                }

                Spacer(minLength: 0)

                // Distance + Compass bearing badge
                HStack {
                    Text(String(format: "%.1f mi %@", flight.distanceMiles, flight.compassDirection))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(flight.isDirectlyOverhead ? .black : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(flight.isDirectlyOverhead ? Color.green : Color.white.opacity(0.15))
                        )

                    Spacer()

                    if let knots = flight.velocityKnots {
                        Text("\(knots) kts")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.yellow.opacity(0.8))

                    Text("Clear Skies")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("No planes within 25 mi")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(10)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        HStack(spacing: 12) {
            // Radar scope on the left
            RadarScopeWidgetView(flights: entry.flights, maxRadiusMiles: UserDefaults.appGroup.searchRadiusMiles)
                .frame(width: 105, height: 105)

            // Flight details on the right
            VStack(alignment: .leading, spacing: 3) {
                // Top row: Airline logo + Flight Number + Airline Name + Refresh Intent Button
                HStack(spacing: 6) {
                    if let flight = entry.closestFlight {
                        AirlineLogoView(logoData: flight.airlineLogoData, fallbackText: flight.callsign, size: 28, isCommercial: flight.isCommercial)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(flight.flightNumber ?? flight.callsign)
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)

                            Text(flight.airlineName ?? flight.originCountry)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("CLEAR SKIES")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button(intent: RefreshFlightsIntent()) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                            Text("SCAN")
                        }
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Route & Aircraft model badge
                if let flight = entry.closestFlight {
                    HStack(spacing: 6) {
                        if let route = flight.routeString {
                            HStack(spacing: 3) {
                                Image(systemName: "point.topleft.filled.down.to.point.bottomright.curvepath")
                                    .font(.system(size: 8))
                                Text(route)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(.cyan)
                        }

                        if let model = flight.aircraftModel {
                            Text("• \(model)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Divider().overlay(Color.white.opacity(0.1)).padding(.vertical, 1)

                if let flight = entry.closestFlight {
                    // Metrics Grid
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ALTITUDE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 2) {
                                Text(flight.altitudeFeet.map { "\($0.formatted())" } ?? "--")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Image(systemName: flight.climbState.symbol)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(flight.climbState == .climbing ? .green : .secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("SPEED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(flight.velocityKnots.map { "\($0) kts" } ?? "--")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("DISTANCE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f mi", flight.distanceMiles))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(flight.isDirectlyOverhead ? .green : .white)
                        }
                    }

                    Spacer(minLength: 0)

                    // Elevation angle & direction badge
                    HStack {
                        if flight.isDirectlyOverhead {
                            Label("OVERHEAD", systemImage: "sparkles")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green))
                        } else {
                            Text(String(format: "%@ • %.0f° elev", flight.compassDirection, flight.elevationAngle))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }

                        Spacer()

                        Text(entry.date, style: .time)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No aircraft currently detected overhead.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: FlightEntry

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Label("AIRSPACE RADAR", systemImage: "airplane.circle")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)

                Spacer()

                Text("\(entry.flights.count) IN RANGE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Button(intent: RefreshFlightsIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }

            // Radar display
            RadarScopeWidgetView(flights: entry.flights, maxRadiusMiles: UserDefaults.appGroup.searchRadiusMiles)
                .frame(height: 130)

            Divider().overlay(Color.white.opacity(0.1))

            // Overhead list (up to 3 closest)
            VStack(spacing: 5) {
                if entry.flights.isEmpty {
                    Text("No aircraft currently overhead.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                } else {
                    ForEach(entry.flights.prefix(3)) { flight in
                        HStack(spacing: 6) {
                            AirlineLogoView(logoData: flight.airlineLogoData, fallbackText: flight.callsign, size: 24, isCommercial: flight.isCommercial)

                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(flight.flightNumber ?? flight.callsign)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)

                                    if let route = flight.routeString {
                                        Text(route)
                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.cyan)
                                    }
                                }

                                Text([flight.airlineName, flight.aircraftModel].compactMap { $0 }.joined(separator: " • "))
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text(flight.altitudeFeet.map { "\($0.formatted()) ft" } ?? "--")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)

                                Text(String(format: "%.1f mi %@", flight.distanceMiles, flight.compassDirection))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(flight.isDirectlyOverhead ? .green : .secondary)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(flight.isDirectlyOverhead ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }
}

// MARK: - Radar Scope Widget Component
struct RadarScopeWidgetView: View {
    let flights: [Flight]
    let maxRadiusMiles: Double

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    .frame(width: radius * 1.33, height: radius * 1.33)

                Circle()
                    .stroke(Color.cyan.opacity(0.1), lineWidth: 1)
                    .frame(width: radius * 0.66, height: radius * 0.66)

                Path { p in
                    p.move(to: CGPoint(x: center.x, y: center.y - radius))
                    p.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    p.move(to: CGPoint(x: center.x - radius, y: center.y))
                    p.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(Color.cyan.opacity(0.15), lineWidth: 1)

                Circle()
                    .fill(Color.cyan)
                    .frame(width: 5, height: 5)
                    .shadow(color: .cyan, radius: 4)

                ForEach(flights) { flight in
                    let clampedDist = min(flight.distanceMiles, maxRadiusMiles)
                    let normalizedDist = CGFloat(clampedDist / maxRadiusMiles) * radius
                    let bearingRad = CGFloat(flight.bearingDegrees) * .pi / 180.0

                    let xOffset = normalizedDist * sin(bearingRad)
                    let yOffset = -normalizedDist * cos(bearingRad)

                    ZStack {
                        Image(systemName: "airplane")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(flight.isDirectlyOverhead ? Color.green : Color.yellow)
                            .rotationEffect(.degrees((flight.heading ?? 0) - 90))
                            .shadow(color: flight.isDirectlyOverhead ? .green : .yellow, radius: 3)
                    }
                    .position(x: center.x + xOffset, y: center.y + yOffset)
                }
            }
        }
    }
}

// MARK: - Accessory Views (Lock Screen)
#if os(iOS)
struct AccessoryRectangularView: View {
    let entry: FlightEntry

    var body: some View {
        if let flight = entry.closestFlight {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "airplane")
                    Text(flight.flightNumber ?? flight.callsign)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                    if let route = flight.routeString {
                        Text(route)
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                Text("\(flight.altitudeFeet.map { "\($0.formatted()) ft" } ?? "--") • \(String(format: "%.1f mi %@", flight.distanceMiles, flight.compassDirection))")
                    .font(.system(size: 10))
                if let model = flight.aircraftModel {
                    Text(model)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading) {
                Label("Clear Skies", systemImage: "sun.max")
                    .font(.system(size: 11, weight: .semibold))
                Text("No planes overhead")
                    .font(.system(size: 9))
            }
        }
    }
}

struct AccessoryCircularView: View {
    let entry: FlightEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let flight = entry.closestFlight {
                VStack(spacing: 1) {
                    Image(systemName: "airplane")
                        .font(.system(size: 12))
                        .rotationEffect(.degrees((flight.heading ?? 0) - 90))
                    Text(flight.altitudeFeet.map { "\($0 / 1000)k" } ?? "--")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
            } else {
                Image(systemName: "sun.max")
                    .font(.system(size: 14))
            }
        }
    }
}
#endif

#Preview("Small Widget", as: .systemSmall) {
    SkyScanWidget()
} timeline: {
    FlightEntry(date: Date(), flights: Flight.sampleList)
}

#Preview("Medium Widget", as: .systemMedium) {
    SkyScanWidget()
} timeline: {
    FlightEntry(date: Date(), flights: Flight.sampleList)
}

#Preview("Large Widget", as: .systemLarge) {
    SkyScanWidget()
} timeline: {
    FlightEntry(date: Date(), flights: Flight.sampleList)
}

