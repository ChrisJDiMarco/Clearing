import SwiftUI

// MARK: - Ambient background

/// Dimensional background: the warming gradient plus soft mint/gold glow blobs.
/// Used behind the main screens so cards float on real depth.
struct AmbientBackground: View {
    var progress: Double = 0.3

    var body: some View {
        ZStack {
            Theme.heroGradient(progress: progress)
            Circle().fill(Theme.mint.opacity(0.16)).frame(width: 360, height: 360)
                .blur(radius: 100).offset(x: -130, y: -300)
            Circle().fill(Theme.gold.opacity(0.10)).frame(width: 280, height: 280)
                .blur(radius: 100).offset(x: 150, y: -150)
            Circle().fill(Theme.mint.opacity(0.07)).frame(width: 320, height: 320)
                .blur(radius: 110).offset(x: 120, y: 380)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Surfaces

/// Elevated glassmorphic card: frosted material, green tint, top sheen, a fine
/// light border, and layered shadows for real depth.
struct GlassCard: View {
    var cornerRadius: CGFloat = 26
    var glow: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Color(hex: 0x0E2A20).opacity(0.34)))
            .overlay(
                shape.fill(
                    LinearGradient(colors: [.white.opacity(0.12), .clear],
                                   startPoint: .top, endPoint: .center))
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.04)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.38), radius: 16, x: 0, y: 10)
            .shadow(color: Theme.mint.opacity(glow ? 0.20 : 0.06), radius: 24, x: 0, y: 4)
    }
}

/// A hero sub-metric tile (money saved, sessions avoided, …) with a glowing glyph.
struct StatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Theme.mint.opacity(0.18)).frame(width: 36, height: 36).blur(radius: 3)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.mint)
            }
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.cream)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.cream.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 6)
        .background(GlassCard(cornerRadius: 22))
    }
}

// MARK: - Buttons

struct PillButton: View {
    let title: String
    var icon: String? = nil
    var filled: Bool = true
    var tint: Color = Theme.mint
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .bold)) }
                Text(title).font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(filled ? Color(hex: 0x06241A) : Theme.cream)
            .background {
                if filled {
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.brightMint, tint],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(
                            Capsule().fill(
                                LinearGradient(colors: [.white.opacity(0.40), .clear],
                                               startPoint: .top, endPoint: .center))
                        )
                        .shadow(color: tint.opacity(0.45), radius: 16, x: 0, y: 8)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// Gentle press-scale used on tappable surfaces.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Selectable pill (onboarding reasons, options).
struct Chip: View {
    let title: String
    var icon: String? = nil
    var selected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 13, weight: .semibold)) }
            Text(title).font(Theme.rounded(15, .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .foregroundStyle(selected ? Color(hex: 0x06241A) : Theme.cream)
        .background {
            Capsule().fill(
                selected
                ? AnyShapeStyle(LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                               startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(.ultraThinMaterial)
            )
        }
        .overlay(Capsule().strokeBorder(.white.opacity(selected ? 0 : 0.12), lineWidth: 1))
        .shadow(color: selected ? Theme.mint.opacity(0.35) : .clear, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Modifiers

extension View {
    /// Soft elevation shadow for floating surfaces (tab bar, sheets).
    func softShadow(_ color: Color = .black.opacity(0.35),
                    radius: CGFloat = 18, y: CGFloat = 10) -> some View {
        shadow(color: color, radius: radius, x: 0, y: y)
    }
}

// MARK: - Layout

/// Wraps subviews onto multiple lines (used for reason chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Confetti

/// Lightweight falling-confetti burst for milestone celebrations.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let color: Color
        let size: CGFloat
        let rotation: Double
    }

    @State private var animate = false
    private let pieces: [Piece]

    init(count: Int = 90) {
        let colors: [Color] = [Theme.mint, Theme.brightMint, Theme.gold, Theme.cream, Color(hex: 0x9AE6B4)]
        pieces = (0..<count).map { _ in
            Piece(x: .random(in: 0...1),
                  delay: .random(in: 0...0.7),
                  color: colors.randomElement() ?? Theme.mint,
                  size: .random(in: 6...12),
                  rotation: .random(in: 0...360))
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 1.6)
                        .rotationEffect(.degrees(animate ? p.rotation + 220 : p.rotation))
                        .position(x: p.x * geo.size.width,
                                  y: animate ? geo.size.height + 60 : -60)
                        .opacity(animate ? 0 : 1)
                        .animation(.easeIn(duration: 2.4).delay(p.delay), value: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}
