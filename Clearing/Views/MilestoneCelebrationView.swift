import SwiftUI

/// The emotional payoff: confetti, a haptic crescendo, and a shareable badge
/// built for TikTok/IG with zero editing.
struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @Environment(AppModel.self) private var model
    @State private var appeared = false
    @State private var shareImage: Image?

    var body: some View {
        ZStack {
            AmbientBackground(progress: 0.8)

            ConfettiView(count: 48)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("Milestone reached")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.amberInk)
                    .textCase(.uppercase)
                    .tracking(3)
                    .opacity(appeared ? 1 : 0)

                BadgeCard(milestone: milestone)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    if let shareImage {
                        ShareLink(item: shareImage,
                                  preview: SharePreview(milestone.badge, image: shareImage)) {
                            HStack(spacing: 9) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .bold))
                                Text("Share my badge").font(Theme.rounded(17, .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .foregroundStyle(Theme.paper)
                            .background(Capsule().fill(
                                LinearGradient(colors: [Theme.ink, Theme.indigo],
                                               startPoint: .leading, endPoint: .trailing)))
                        }
                        .buttonStyle(PressableStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            AppEvents.log("badge_share_tap", milestone.badge)
                        })
                    }
                    Button("Keep going") {
                        Haptics.soft()
                        onDismiss()
                    }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.mutedInk)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
            renderBadge()
        }
    }

    private func renderBadge() {
        // Defer off the current run-loop turn so the entry animation starts first
        // (ImageRenderer.uiImage blocks the main thread while it rasterizes).
        Task { @MainActor in
            let card = BadgeCard(milestone: milestone)
                .frame(width: 320, height: 520)
            let renderer = ImageRenderer(content: card)
            renderer.scale = 3
            if let ui = renderer.uiImage {
                shareImage = Image(uiImage: ui)
            }
        }
    }
}

/// The shareable badge. Used on screen and rendered to an image for sharing.
struct BadgeCard: View {
    let milestone: Milestone

    private var amount: Int { milestone.day < 1 ? Int(milestone.day * 24) : Int(milestone.day) }
    private var unit: String {
        if milestone.day < 1 { return "HOURS CLEAR" }
        return amount == 1 ? "DAY CLEAR" : "DAYS CLEAR"
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 7) {
                Image(systemName: "diamond.fill")
                Text("CLEARING")
                    .tracking(1.8)
                Spacer()
                Image(systemName: milestone.icon)
            }
            .font(Theme.rounded(12, .bold))
            .foregroundStyle(Theme.amberInk)

            Spacer(minLength: 4)

            VStack(spacing: 4) {
                Text("\(amount)")
                    .font(.system(size: 104, weight: .semibold, design: .serif))
                    .fontWidth(.condensed)
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(unit)
                    .font(Theme.rounded(14, .bold))
                    .tracking(3)
                    .foregroundStyle(Theme.mutedInk)
            }

            VStack(spacing: 8) {
                Text(milestone.badge)
                    .font(Theme.display(29))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(milestone.fact)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.mutedInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Text("one moment at a time")
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.amberInk)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Theme.paper, Theme.canvas],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.icyBlue.opacity(0.75))
                        .frame(width: 180, height: 180)
                        .blur(radius: 36)
                        .offset(x: 76, y: -78)
                }
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1))
                .shadow(color: Theme.indigo.opacity(0.13), radius: 22, x: 0, y: 14)
        )
        .padding(.horizontal, 28)
    }
}
