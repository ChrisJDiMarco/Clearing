import SwiftUI

/// The crystal is the ornament. The interface around it stays quiet, warm and legible.
enum Theme {
    // Semantic colors for new screens. Legacy aliases below keep existing views
    // consistent while their layouts are refreshed.
    static let paper      = Color(hex: 0xFFFEFC)
    static let canvas     = Color(hex: 0xF7F5F0)
    static let ink        = Color(hex: 0x19232A)
    static let mutedInk   = Color(hex: 0x626C74)
    static let amber      = Color(hex: 0xC78643)
    static let amberInk   = Color(hex: 0x86552B)
    static let amberLight = Color(hex: 0xEFD2AD)
    static let indigo     = Color(hex: 0x141E2D)
    static let icyBlue    = Color(hex: 0xDCECF4)
    static let hairline   = Color(hex: 0xD9DADC)
    static let danger     = Color(hex: 0xA55C4A) // calm but clear on light surfaces

    static let cream      = ink
    static let mint       = amberInk
    static let brightMint = amberLight
    static let gold       = amber
    static let deepGreen  = ink
    static let forest     = indigo

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// A still, warm backdrop. Progress gently lifts the light without changing
    /// the identity of the screen or putting motion behind readable text.
    static func heroGradient(progress p: Double) -> LinearGradient {
        let t = min(max(p, 0), 1)
        let top = Color(
            .sRGB,
            red:   0.969 + 0.024 * t,
            green: 0.961 + 0.027 * t,
            blue:  0.941 + 0.047 * t,
            opacity: 1
        )
        return LinearGradient(
            colors: [top, paper, canvas],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Soft radial glow placed behind the hero number.
    static func glow(progress p: Double) -> RadialGradient {
        let t = min(max(p, 0), 1)
        let core = amberLight.opacity(0.14 + 0.14 * t)
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
