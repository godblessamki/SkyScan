import SwiftUI
import CoreGraphics
import ImageIO

public struct AirlineLogoView: View {
    public let logoData: Data?
    public let fallbackText: String
    public let size: CGFloat
    public let isCommercial: Bool

    public init(logoData: Data?, fallbackText: String, size: CGFloat = 28, isCommercial: Bool = false) {
        self.logoData = logoData
        self.fallbackText = fallbackText
        self.size = size
        self.isCommercial = isCommercial
    }

    public var body: some View {
        Group {
            if let data = logoData, let cgImg = makeCGImage(from: data) {
                // Real Airline Logo: Solid White Card (bypasses liquid glass, vibrancy & transparency)
                Image(decorative: cgImg, scale: 2.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .compositingGroup()
            } else {
                // General Aviation / Private Aircraft / Missing Logo Fallback: Sleek avionics dark badge
                ZStack {
                    Color.white.opacity(0.12)
                    if isCommercial {
                        Text(fallbackText.prefix(2).uppercased())
                            .font(.system(size: max(8, size * 0.42), weight: .black, design: .monospaced))
                            .foregroundStyle(.cyan)
                    } else {
                        Image(systemName: "airplane")
                            .font(.system(size: size * 0.48, weight: .semibold))
                            .foregroundStyle(.cyan.opacity(0.85))
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
