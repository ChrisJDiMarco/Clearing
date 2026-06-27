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
            LinearGradient(colors: [Color(hex: 0x123A2C), Color(hex: 0x07150F)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("Milestone reached")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.gold)
                    .textCase(.uppercase)
                    .tracking(3)
                    .opacity(appeared ? 1 : 0)

                BadgeCard(milestone: milestone, days: model.daysClean())
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
                            .foregroundStyle(Color(hex: 0x06241A))
                            .background(Capsule().fill(
                                LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                               startPoint: .leading, endPoint: .trailing)))
                        }
                        .buttonStyle(PressableStyle())
                    }
                    Button("Keep going") {
                        Haptics.soft()
                        onDismiss()
                    }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.6))
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
            let card = BadgeCard(milestone: milestone, days: model.daysClean())
                .frame(width: 320, height: 400)
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
    let days: Int

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.gold.opacity(0.3), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 130, height: 130)
                Circle()
                    .stroke(Theme.gold, lineWidth: 2)
                    .frame(width: 104, height: 104)
                Image(systemName: milestone.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.brightMint],
                                                    startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 6) {
                Text(milestone.badge)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                Text(milestone.fact)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.cream.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
            }

            HStack(spacing: 6) {
                Image(systemName: "leaf.fill").font(.system(size: 12))
                Text("\(days) days clear · Clearing")
                    .font(Theme.rounded(12, .semibold))
            }
            .foregroundStyle(Theme.mint)
            .padding(.top, 2)
        }
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0x0C2219))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Theme.gold.opacity(0.35), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }
}
