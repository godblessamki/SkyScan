import SwiftUI
import CoreLocation

public struct RadarView: View {
    let flights: [Flight]
    let centerLocation: CLLocationCoordinate2D
    let radiusMiles: Double
    @Binding var selectedFlight: Flight?

    @State private var sweepAngle: Double = 0

    public init(
        flights: [Flight],
        centerLocation: CLLocationCoordinate2D,
        radiusMiles: Double,
        selectedFlight: Binding<Flight?>
    ) {
        self.flights = flights
        self.centerLocation = centerLocation
        self.radiusMiles = radiusMiles
        self._selectedFlight = selectedFlight
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = (size / 2) * 0.88

            ZStack {
                // Background dark radial gradient
                RadialGradient(
                    colors: [
                        Color(red: 0.04, green: 0.08, blue: 0.14),
                        Color(red: 0.01, green: 0.02, blue: 0.05)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
                .clipShape(Circle())

                // Concentric range rings
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { frac in
                    Circle()
                        .stroke(Color.cyan.opacity(frac == 1.0 ? 0.35 : 0.15), lineWidth: frac == 1.0 ? 1.5 : 1)
                        .frame(width: radius * 2 * frac, height: radius * 2 * frac)

                    // Ring mileage labels
                    Text(String(format: "%.0f mi", radiusMiles * frac))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.cyan.opacity(0.4))
                        .position(x: center.x, y: center.y - (radius * frac) + 8)
                }

                // Crosshair lines
                Path { p in
                    p.move(to: CGPoint(x: center.x, y: center.y - radius))
                    p.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    p.move(to: CGPoint(x: center.x - radius, y: center.y))
                    p.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)

                // Diagonal guide lines
                Path { p in
                    let offset = radius * 0.7071
                    p.move(to: CGPoint(x: center.x - offset, y: center.y - offset))
                    p.addLine(to: CGPoint(x: center.x + offset, y: center.y + offset))
                    p.move(to: CGPoint(x: center.x - offset, y: center.y + offset))
                    p.addLine(to: CGPoint(x: center.x + offset, y: center.y - offset))
                }
                .stroke(Color.cyan.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Cardinal direction letters
                VStack {
                    Text("N")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                    Spacer()
                    Text("S")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                .frame(height: radius * 2 + 36)

                HStack {
                    Text("W")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Spacer()
                    Text("E")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                .frame(width: radius * 2 + 36)

                // Rotating radar sweep beam
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.0),
                        Color.cyan.opacity(0.0),
                        Color.cyan.opacity(0.35)
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                )
                .clipShape(Circle())
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(sweepAngle))

                // User Location center point
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                        .shadow(color: .cyan, radius: 4)
                }

                // Flight blips
                ForEach(flights) { flight in
                    let clampedDist = min(flight.distanceMiles, radiusMiles)
                    let normDist = CGFloat(clampedDist / radiusMiles) * radius
                    let bearingRad = CGFloat(flight.bearingDegrees) * .pi / 180.0
                    let xPos = center.x + normDist * sin(bearingRad)
                    let yPos = center.y - normDist * cos(bearingRad)

                    let isSelected = selectedFlight?.id == flight.id

                    Button {
                        selectedFlight = flight
                    } label: {
                        VStack(spacing: 2) {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                }

                                Image(systemName: "airplane")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(flight.isDirectlyOverhead ? Color.green : Color.yellow)
                                    .rotationEffect(.degrees((flight.heading ?? 0) - 90))
                                    .shadow(color: flight.isDirectlyOverhead ? .green : .yellow, radius: 5)
                            }

                            Text(flight.callsign)
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundStyle(isSelected ? .white : .cyan)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(3)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(x: xPos, y: yPos)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    sweepAngle = 360
                }
            }
        }
    }
}
