import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
            #if os(macOS)
            if let data = logoData, let nsImg = makeNSImage(from: data) {
                logoCard(Image(nsImage: nsImg))
            } else {
                fallbackCard
            }
            #else
            if let data = logoData, let uiImg = UIImage(data: data) {
                logoCard(Image(uiImage: uiImg))
            } else {
                fallbackCard
            }
            #endif
        }
    }

    @ViewBuilder
    private func logoCard(_ image: Image) -> some View {
        image
            .renderingMode(.original)
            .interpolation(.high)
            .antialiased(true)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(size > 30 ? 3 : 2)
            .frame(width: size, height: size)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: size > 30 ? 8 : 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size > 30 ? 8 : 6, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .compositingGroup()
    }

    private var fallbackCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size > 30 ? 8 : 6, style: .continuous)
                .fill(Color(red: 0.08, green: 0.12, blue: 0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: size > 30 ? 8 : 6, style: .continuous)
                        .stroke(isCommercial ? Color.cyan.opacity(0.4) : Color.white.opacity(0.15), lineWidth: 1)
                )

            if isCommercial {
                Text(fallbackText.prefix(2).uppercased())
                    .font(.system(size: max(8, size * 0.40), weight: .black, design: .monospaced))
                    .foregroundStyle(.cyan)
            } else {
                Image(systemName: "airplane")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(.cyan.opacity(0.85))
            }
        }
        .frame(width: size, height: size)
    }

    #if os(macOS)
    private func makeNSImage(from data: Data) -> NSImage? {
        guard let img = NSImage(data: data) else { return nil }
        img.isTemplate = false // Never treat as monochrome template mask
        return img
    }
    #endif
}
