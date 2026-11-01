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
            if let data = logoData, let nsImg = makeNSImage(from: data) {
                Image(nsImage: nsImg)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            } else {
                fallback
            }
            #else
            if let data = logoData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            } else {
                fallback
            }
            #endif
        }
        .frame(width: size, height: size)
        .background(Color.white) // 100% solid opaque background to block liquid glass & transparency
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .compositingGroup() // Isolates the view from liquid glass, backdrop filters & vibrancy shaders
    }

    #if os(macOS)
    private func makeNSImage(from data: Data) -> NSImage? {
        guard let img = NSImage(data: data) else { return nil }
        img.isTemplate = false // Never treat as monochrome template mask
        return img
    }
    #endif

    private var fallback: some View {
        ZStack {
            Color(white: 0.15)
            Text(fallbackText.prefix(2).uppercased())
                .font(.system(size: max(8, size * 0.42), weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan)
        }
    }
}
