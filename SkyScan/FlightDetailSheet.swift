import SwiftUI

public struct FlightDetailSheet: View {
    let flight: Flight
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Header Airline Card
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            AirlineLogoView(logoData: flight.airlineLogoData, fallbackText: flight.callsign, size: 52, isCommercial: flight.isCommercial)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(flight.flightNumber ?? flight.callsign)
                                        .font(.system(size: 24, weight: .black, design: .monospaced))
                                        .foregroundStyle(.white)

                                    if flight.isDirectlyOverhead {
                                        Text("OVERHEAD")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color.green))
                                    }
                                }

                                Text(flight.airlineName ?? flight.originCountry)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.cyan)
                            }

                            Spacer()
                        }

                        // Route display if available
                        if let route = flight.routeString {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "airplane.departure")
                                    Text(flight.originAirport ?? "ORIGIN")
                                }
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.cyan)

                                Spacer()

                                HStack(spacing: 6) {
                                    Text(flight.destinationAirport ?? "DEST")
                                    Image(systemName: "airplane.arrival")
                                }
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.12)))
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))

                    // Aircraft Model & Equipment
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AIRCRAFT EQUIPMENT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(flight.aircraftModel ?? "Commercial Jet")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)

                                if let typeCode = flight.aircraftTypeCode {
                                    Text("ICAO Type: \(typeCode)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if let reg = flight.registration {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(reg)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.cyan)
                                    Text("Tail / Reg")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

                    // Core Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(
                            title: "ALTITUDE",
                            value: flight.altitudeFeet.map { "\($0.formatted()) ft" } ?? "N/A",
                            subvalue: flight.altitudeMeters.map { "\(Int($0)) m" },
                            icon: flight.climbState.symbol,
                            iconColor: flight.climbState == .climbing ? .green : (flight.climbState == .descending ? .orange : .secondary)
                        )

                        MetricCard(
                            title: "DISTANCE",
                            value: String(format: "%.1f mi", flight.distanceMiles),
                            subvalue: String(format: "%.1f km", flight.distanceKm),
                            icon: "location.north.circle",
                            iconColor: .cyan
                        )

                        MetricCard(
                            title: "GROUND SPEED",
                            value: flight.velocityKnots.map { "\($0) kts" } ?? "N/A",
                            subvalue: flight.velocityMps.map { "\(Int($0 * 3.6)) km/h" },
                            icon: "gauge.with.needle",
                            iconColor: .yellow
                        )

                        MetricCard(
                            title: "BEARING",
                            value: "\(flight.compassDirection) (\(Int(flight.bearingDegrees))°)",
                            subvalue: String(format: "Elev: %.0f°", flight.elevationAngle),
                            icon: "safari",
                            iconColor: .purple
                        )

                        MetricCard(
                            title: "HEADING / TRACK",
                            value: flight.heading.map { "\(Int($0))°" } ?? "N/A",
                            subvalue: "True North",
                            icon: "airplane",
                            iconColor: .blue
                        )

                        MetricCard(
                            title: "TRANSPONDER ICAO",
                            value: flight.id.uppercased(),
                            subvalue: "Mode S",
                            icon: "barcode",
                            iconColor: .secondary
                        )
                    }

                    // External Links
                    VStack(spacing: 10) {
                        Link(destination: URL(string: "https://www.flightradar24.com/\(flight.callsign)")!) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text("Track Live on Flightradar24")
                                Spacer()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.3)))
                        }

                        Link(destination: URL(string: "https://opensky-network.org/aircraft-profile?icao24=\(flight.id)")!) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("OpenSky Network Aircraft Profile")
                                Spacer()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.cyan)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Flight Info")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subvalue: String?
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            if let sub = subvalue {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }
}
