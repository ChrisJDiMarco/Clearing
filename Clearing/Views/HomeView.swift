import SwiftUI

/// The whole app in one screen — and the entire TikTok ad.
/// A live-counting day number, money saved + sessions avoided ticking up,
/// a satisfying daily check-in, and the next milestone within reach.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Binding var showSettings: Bool
    var onDebugCelebrate: () -> Void = {}

    @State private var showSlipDialog = false

    var body: some View {
        ZStack {
            AmbientBackground(progress: model.dawnProgress())   // outside the timeline: heavy blurs render once, not 10x/sec
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let now = context.date
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        hero(now: now)
                        statRow(now: now)
                        checkInSection
                        nextMilestoneCard(now: now)
                        #if DEBUG
                        debugRow
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)
            }
        }
        .confirmationDialog("Log a slip?", isPresented: $showSlipDialog, titleVisibility: .visible) {
            Button("I used — reset my streak", role: .destructive) {
                Haptics.warning()
                model.logSlip()
            }
            Button("Never mind", role: .cancel) {}
        } message: {
            Text("That took honesty. Your streak resets, but everything your body has healed so far still counts.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.mint)
                Text("Clearing")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.cream)
            }
            Spacer()
            Button {
                Haptics.soft()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.cream.opacity(0.5))
            }
        }
        .padding(.top, 4)
    }

    // MARK: Hero number

    private func hero(now: Date) -> some View {
        let days = model.daysClean(asOf: now)
        let progress = model.progressToNextMilestone(asOf: now)
        let dawn = model.dawnProgress(asOf: now)
        return ZStack {
            Circle()
                .fill(Theme.glow(progress: dawn))
                .frame(width: 340, height: 340)
                .blur(radius: 14)

            // Inner glass disc for dimensional depth behind the number
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(Color(hex: 0x0C211B).opacity(0.30)))
                .overlay(Circle().strokeBorder(.white.opacity(0.06), lineWidth: 1))
                .frame(width: 248, height: 248)
                .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 12)

            // Track
            Circle()
                .stroke(.white.opacity(0.07), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 292, height: 292)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [Theme.mint, Theme.brightMint],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 292, height: 292)
                .shadow(color: Theme.mint.opacity(0.5), radius: 9, x: 0, y: 0)

            VStack(spacing: 2) {
                Text("\(days)")
                    .font(Theme.rounded(94, .heavy))
                    .foregroundStyle(Theme.cream)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: days)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                Text(days == 1 ? "day clear" : "days clear")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .frame(height: 340)
        .padding(.top, 6)
    }

    // MARK: Stats

    private func statRow(now: Date) -> some View {
        HStack(spacing: 12) {
            StatTile(icon: "banknote.fill",
                     value: model.moneySaved(asOf: now).asMoneyLive,
                     label: "saved")
            StatTile(icon: "leaf.arrow.triangle.circlepath",
                     value: "\(Int(model.sessionsAvoided(asOf: now)))",
                     label: "sessions skipped")
            StatTile(icon: "clock.arrow.circlepath",
                     value: "\(Int(model.hoursReclaimed(asOf: now)))h",
                     label: "reclaimed")
        }
    }

    // MARK: Check-in

    private var checkInSection: some View {
        VStack(spacing: 10) {
            if model.hasCheckedInToday {
                HStack(spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Checked in — clear today")
                        .font(Theme.rounded(17, .semibold))
                }
                .foregroundStyle(Theme.mint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Capsule().fill(Theme.mint.opacity(0.12)))
            } else {
                PillButton(title: "I stayed clear today", icon: "checkmark") {
                    Haptics.success()
                    model.checkIn()
                }
            }

            Button {
                Haptics.soft()
                showSlipDialog = true
            } label: {
                Text("I slipped")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.cream.opacity(0.4))
            }
        }
    }

    // MARK: Next milestone

    private func nextMilestoneCard(now: Date) -> some View {
        Group {
            if let next = model.nextMilestone(asOf: now) {
                let daysToGo = max(0, next.day - model.fractionalDaysClean(asOf: now))
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: next.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next: \(next.title)")
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.cream)
                            Text(daysToGoLabel(daysToGo))
                                .font(Theme.rounded(13, .medium))
                                .foregroundStyle(Theme.cream.opacity(0.5))
                        }
                        Spacer()
                    }
                    ProgressView(value: model.progressToNextMilestone(asOf: now))
                        .tint(Theme.gold)
                    Text(next.fact)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .background(GlassCard())
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.gold)
                    Text("Every milestone cleared.")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.cream)
                    Text("Your tolerance is back to baseline. You did the whole thing.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(GlassCard())
            }
        }
    }

    private func daysToGoLabel(_ days: Double) -> String {
        if days <= 0 { return "Reached" }
        if days < 1 {
            let hours = max(1, Int(days * 24))
            return "\(hours) hour\(hours == 1 ? "" : "s") to go"
        }
        let whole = Int(days.rounded(.up))
        return "\(whole) day\(whole == 1 ? "" : "s") to go"
    }

    #if DEBUG
    private var debugRow: some View {
        HStack(spacing: 10) {
            Button("+7 days") {
                model.debugBackdate(days: model.daysClean() + 7)
                onDebugCelebrate()
            }
            Button("Reset") { model.resetAll() }
        }
        .font(Theme.rounded(13, .semibold))
        .foregroundStyle(Theme.cream.opacity(0.35))
        .padding(.top, 6)
    }
    #endif
}
