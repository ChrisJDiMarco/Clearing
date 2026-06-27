import SwiftUI

/// Intercepts the relapse moment with a 60-second guided breath.
/// A near-slip becomes a logged win — the kind alternative to shame.
struct UrgeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var expand = false
    @State private var phase = "Breathe in"
    @State private var secondsLeft = 60
    @State private var finished = false

    private let breathTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    private let countdown = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.heroGradient(progress: 0.3).ignoresSafeArea()

            if finished {
                finishedView
            } else {
                breathingView
            }
        }
        .onReceive(breathTimer) { _ in
            guard !finished else { return }
            phase = (phase == "Breathe in") ? "Breathe out" : "Breathe in"
            Haptics.soft()
        }
        .onReceive(countdown) { _ in
            guard !finished else { return }
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                complete()
            }
        }
        .onAppear { expand = true }
    }

    // MARK: Breathing

    private var breathingView: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.glow(progress: 1))
                    .frame(width: 320, height: 320)
                Circle()
                    .fill(
                        LinearGradient(colors: [Theme.brightMint.opacity(0.9), Theme.mint.opacity(0.5)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 200, height: 200)
                    .scaleEffect(expand ? 1.25 : 0.7)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: expand)
                Text(phase)
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Color(hex: 0x06241A))
            }
            .frame(height: 340)
            Spacer()
            VStack(spacing: 8) {
                Text("This craving will peak and pass.")
                    .font(Theme.rounded(19, .semibold))
                    .foregroundStyle(Theme.cream)
                Text("Most urges fade within 3 minutes. Ride this one out — you've got 60 seconds.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.cream.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Text("\(secondsLeft)s")
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(Theme.mint)
                    .monospacedDigit()
                    .padding(.top, 8)
            }
            Spacer()
            Button("I beat it early") { complete() }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.cream.opacity(0.6))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.cream.opacity(0.5))
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.08)))
            }
        }
        .padding(.top, 16)
    }

    // MARK: Finished

    private var finishedView: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(Theme.glow(progress: 1)).frame(width: 220, height: 220)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                                    startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 8) {
                Text("You beat it.")
                    .font(Theme.rounded(30, .bold))
                    .foregroundStyle(Theme.cream)
                Text("That's urge #\(model.urgesBeaten) you've ridden out. Your streak is still alive — and that craving had no power.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.cream.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            PillButton(title: "Back to my progress") { dismiss() }
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
    }

    private func complete() {
        guard !finished else { return }
        Haptics.success()
        model.beatUrge()
        withAnimation(.smooth) { finished = true }
    }
}
