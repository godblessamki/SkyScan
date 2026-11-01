import SwiftUI

public struct AirlineLogoView: View {
    public let logoData: Data?
    public let fallbackText: String
    public let size: CGFloat

    public init(logoData: Data?, fallbackText: String, size: CGFloat = 28) {
        self.logoData = logoData
        self.fallbackText = fallbackText
        self.size = size
    }

    public var body: some View {
        ZStack {
            #if os(macOS)
            if let data = logoData, let nsImg = NSImage(data: data) {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            } else {
                fallback
            }
            #else
            if let data = logoData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            } else {
                fallback
            }
            #endif
        }
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }

    private var fallback: some View {
        ZStack {
            Color.cyan.opacity(0.25)
            Text(fallbackText.prefix(2).uppercased())
                .font(.system(size: max(8, size * 0.42), weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
        }
    }
}
