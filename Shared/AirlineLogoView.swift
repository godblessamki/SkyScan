import SwiftUI
import ImageIO

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct AirlineLogoView: View {
    public let logoData: Data?
    public let airlineIATA: String?
    public let fallbackText: String
    public let size: CGFloat
    public let isCommercial: Bool

    public init(logoData: Data?, fallbackText: String, size: CGFloat = 28, isCommercial: Bool = false, airlineIATA: String? = nil) {
        self.logoData = logoData
        self.airlineIATA = airlineIATA
        self.fallbackText = fallbackText
        self.size = size
        self.isCommercial = isCommercial
    }

    public init(flight: Flight, size: CGFloat = 28) {
        self.logoData = flight.airlineLogoData
        self.airlineIATA = flight.airlineIATA
        self.fallbackText = flight.airlineIATA ?? flight.callsign
        self.size = size
        self.isCommercial = flight.isCommercial
    }

    public var body: some View {
        Group {
            if let data = resolveData(), let cgImage = makeCGImage(from: data) {
                // Use Image(decorative:scale:) — WidgetKit can archive CGImage-backed
                // images across process boundaries, unlike Image(nsImage:) which gets
                // filtered out by WidgetKit's chrono archiver on macOS.
                // .renderingMode(.original) prevents SwiftUI from treating it as a
                // monochrome template mask (which caused white-on-white in dark mode).
                logoCard(
                    Image(decorative: cgImage, scale: 2.0)
                        .renderingMode(.original)
                )
            } else {
                fallbackCard
            }
        }
    }

    /// Resolves logo data from passed data, disk cache, or prebundled offline catalog
    private func resolveData() -> Data? {
        if let data = logoData, !data.isEmpty {
            return data
        }
        if let key = airlineIATA ?? (isCommercial ? fallbackText : nil) {
            let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2).uppercased()
            if let diskData = AirlineLogoDiskCache.load(key: clean) {
                return diskData
            }
        }
        return nil
    }

    @ViewBuilder
    private func logoCard(_ image: Image) -> some View {
        image
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

    /// Creates a CGImage from PNG/JPEG Data using ImageIO.
    /// CGImage-backed SwiftUI Images archive correctly across WidgetKit's
    /// out-of-process rendering boundary, unlike NSImage-backed ones.
    private func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
