import SwiftUI

/// Visual system for Clearing. The whole product wedge is craft, so the palette
/// and motion live in one place and stay consistent everywhere.
enum Theme {
    static let cream      = Color(hex: 0xF4F1E8)
    static let mint       = Color(hex: 0x86E5B0)
    static let brightMint = Color(hex: 0xB8F2C9)
    static let gold       = Color(hex: 0xF0C674)
    static let deepGreen  = Color(hex: 0x0C211B)
    static let forest     = Color(hex: 0x12352A)
    static let danger     = Color(hex: 0xE89A78)   // warm, never harsh — tone matters

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Hero background. Warms from cool forest night toward dawn as the streak grows.
    static func heroGradient(progress p: Double) -> LinearGradient {
        let t = min(max(p, 0), 1)
        let top = Color(
            .sRGB,
            red:   0.05 + 0.32 * t,
            green: 0.14 + 0.16 * t,
            blue:  0.11 + 0.02 * t,
            opacity: 1
        )
        return LinearGradient(
            colors: [top, Color(hex: 0x0C211B), Color(hex: 0x050F0A)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Soft radial glow placed behind the hero number.
    static func glow(progress p: Double) -> RadialGradient {
        let t = min(max(p, 0), 1)
        let core = mint.opacity(0.18 + 0.22 * t)
        return RadialGradient(
            colors: [core, .clear],
            center: .center,
            startRadius: 4,
            endRadius: 260
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue:  Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension Double {
    // Cached formatters — `asMoneyLive` is called ~10x/sec from the hero TimelineView,
    // so we never allocate a NumberFormatter per call. Main-thread only (SwiftUI body).
    private static let moneyFormatterNoCents: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"
        f.minimumFractionDigits = 0; f.maximumFractionDigits = 0; return f
    }()
    private static let moneyLiveFormatter: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2; return f
    }()

    /// "$1,284" style — no cents for big numbers (never mutates a shared formatter).
    var asMoney: String {
        let f = self >= 100 ? Double.moneyFormatterNoCents : Double.moneyLiveFormatter
        return f.string(from: NSNumber(value: self)) ?? "$0"
    }

    /// "$84.21" live-ticking style — always two decimals.
    var asMoneyLive: String {
        Double.moneyLiveFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
