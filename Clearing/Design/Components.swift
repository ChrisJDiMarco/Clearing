import SwiftUI

// MARK: - Ambient background

/// Porcelain backdrop with a trace of the crystal's amber light and cool edge.
struct AmbientBackground: View {
    var progress: Double = 0.3

    var body: some View {
        ZStack {
            Theme.heroGradient(progress: progress)
            Circle().fill(Theme.amberLight.opacity(0.16)).frame(width: 320, height: 320)
                .blur(radius: 110).offset(x: -125, y: -120)
            Circle().fill(Theme.icyBlue.opacity(0.26)).frame(width: 290, height: 290)
                .blur(radius: 110).offset(x: 150, y: -70)
            Circle().fill(Theme.indigo.opacity(0.035)).frame(width: 340, height: 340)
                .blur(radius: 130).offset(x: 100, y: 460)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Surfaces

/// Quiet translucent porcelain surface. Deliberately less ornate than the rock.
struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    var glow: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Theme.paper.opacity(0.72)))
            .overlay(
                shape.fill(
                    LinearGradient(colors: [.white.opacity(0.52), .clear],
                                   startPoint: .top, endPoint: .center))
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.90), Theme.hairline.opacity(0.7)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            )
            .shadow(color: Theme.indigo.opacity(0.08), radius: 24, x: 0, y: 12)
            .shadow(color: Theme.amber.opacity(glow ? 0.14 : 0.02), radius: 28, x: 0, y: 3)
    }
}

/// A hero sub-metric tile (money saved, sessions avoided, …).
struct StatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Theme.amberLight.opacity(0.32)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.mutedInk)
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
    var trailingIcon: String? = nil
    var filled: Bool = true
    var tint: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .bold)) }
                Text(title).font(Theme.rounded(17, .semibold))
                if let trailingIcon { Image(systemName: trailingIcon).font(.system(size: 16, weight: .medium)) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(filled ? (tint == Theme.ink || tint == Theme.indigo ? Theme.paper : Theme.ink) : Theme.ink)
            .background {
                if filled {
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.92), tint],
                                             startPoint: .top, endPoint: .bottom))
                        .shadow(color: Theme.indigo.opacity(0.15), radius: 12, x: 0, y: 7)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Theme.paper.opacity(0.50)))
                        .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.36), lineWidth: 1))
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
        .foregroundStyle(Theme.ink)
        .background {
            Capsule().fill(
                selected
                ? AnyShapeStyle(Theme.icyBlue)
                : AnyShapeStyle(Theme.paper.opacity(0.64))
            )
        }
        .overlay(Capsule().strokeBorder(Theme.ink.opacity(selected ? 0.42 : 0.12), lineWidth: 1))
        .shadow(color: selected ? Theme.indigo.opacity(0.10) : .clear, radius: 8, x: 0, y: 3)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Modifiers

extension View {
    /// Soft elevation shadow for floating surfaces (tab bar, sheets).
    func softShadow(_ color: Color = Theme.indigo.opacity(0.11),
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
        let colors: [Color] = [Theme.amber, Theme.amberLight, Theme.icyBlue, Theme.indigo, Theme.paper]
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
