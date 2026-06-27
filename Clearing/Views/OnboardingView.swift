import SwiftUI

/// Quiz-style onboarding that names the feeling, not the features. Ends on a
/// personalized "what's waiting" projection that primes the paywall, then builds the plan.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    @State private var step = 0
    @State private var lastUsed: LastUsed? = nil
    @State private var weeklySpend: Double = 45
    @State private var sessions: SessionFrequency? = nil
    @State private var reasons: Set<Reason> = []
    @State private var building = false
    @State private var welcomeGlow = false
    @State private var buildMsg = 0

    private let totalSteps = 6
    private let buildMessages = ["Reading your patterns…", "Mapping your recovery timeline…", "Tuning your plan…"]

    var body: some View {
        ZStack {
            AmbientBackground(progress: 0.15)

            if building {
                buildingView
            } else {
                VStack(spacing: 0) {
                    progressBar
                    Spacer(minLength: 0)
                    content
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)))
                        .id(step)
                    Spacer(minLength: 0)
                    footer.padding(.horizontal, 24).padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            #if DEBUG
            if let s = ProcessInfo.processInfo.environment["DEMO_ONBOARD_STEP"], let n = Int(s), n < totalSteps {
                weeklySpend = 60
                reasons = [.clarity, .sleep, .dreams, .money]
                lastUsed = .yesterday
                sessions = .few
                step = n
            }
            #endif
        }
    }

    // MARK: Steps

    @ViewBuilder private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: lastUsedStep
        case 2: spendStep
        case 3: frequencyStep
        case 4: reasonsStep
        default: projectionStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Theme.glow(progress: 1))
                    .frame(width: 220, height: 220)
                    .scaleEffect(welcomeGlow ? 1.08 : 0.86)
                    .opacity(welcomeGlow ? 1 : 0.7)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: welcomeGlow)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                                    startPoint: .top, endPoint: .bottom))
                    .scaleEffect(welcomeGlow ? 1 : 0.9)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6), value: welcomeGlow)
            }
            VStack(spacing: 10) {
                Text("Clearing")
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(Theme.cream)
                Text("Your tolerance break,\nbeautifully tracked.")
                    .font(Theme.rounded(18, .medium))
                    .foregroundStyle(Theme.cream.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            Text("No shame. No streaks you can fake.\nJust your real progress, day by day.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.cream.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .onAppear { welcomeGlow = true }
    }

    private var lastUsedStep: some View {
        QuestionScaffold(title: "When did you last use?",
                         subtitle: "This sets your starting point. You can change it later.") {
            VStack(spacing: 12) {
                ForEach(LastUsed.allCases) { option in
                    SelectRow(title: option.label, selected: lastUsed == option) {
                        lastUsed = option
                    }
                }
            }
        }
    }

    private var spendStep: some View {
        QuestionScaffold(title: "How much did it cost you?",
                         subtitle: "Roughly, per week. We'll turn this into money back in your pocket.") {
            VStack(spacing: 28) {
                Text(weeklySpend.asMoney + " / week")
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(Theme.brightMint)
                    .contentTransition(.numericText())
                Slider(value: $weeklySpend, in: 10...250, step: 5)
                    .tint(Theme.mint)
                Text("≈ " + (weeklySpend * 52).asMoney + " a year")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.cream.opacity(0.5))
            }
        }
    }

    private var frequencyStep: some View {
        QuestionScaffold(title: "How often was it?",
                         subtitle: "An honest guess is perfect.") {
            VStack(spacing: 12) {
                ForEach(SessionFrequency.allCases) { option in
                    SelectRow(title: option.label, selected: sessions == option) {
                        sessions = option
                    }
                }
            }
        }
    }

    private var reasonsStep: some View {
        QuestionScaffold(title: "Why now?",
                         subtitle: "Pick what matters. We'll remind you on the hard days.") {
            FlowLayout(spacing: 10) {
                ForEach(Reason.allCases) { reason in
                    Button {
                        Haptics.soft()
                        if reasons.contains(reason) { reasons.remove(reason) }
                        else { reasons.insert(reason) }
                    } label: {
                        Chip(title: reason.rawValue, icon: reason.icon, selected: reasons.contains(reason))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private var projectionStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Here's what's waiting")
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.cream)
                Text("Based on your answers, this is the year ahead.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.cream.opacity(0.55))
            }

            VStack(spacing: 0) {
                ProjectionRow(icon: "banknote.fill",
                              title: (weeklySpend * 52).asMoney + " back",
                              detail: "in your pocket this year", tint: Theme.mint)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "moon.stars.fill",
                              title: "Vivid dreams return",
                              detail: "around day 7, as REM rebounds", tint: Theme.brightMint)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "sparkles",
                              title: "Mental clarity sharpens",
                              detail: "around day 14", tint: Theme.gold)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "leaf.fill",
                              title: "Tolerance fully resets",
                              detail: "by day 90 — back to baseline", tint: Theme.mint)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .background(GlassCard())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buildingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.mint)
            Text(buildMessages[min(buildMsg, buildMessages.count - 1)])
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.cream)
                .contentTransition(.opacity)
                .id(buildMsg)
            Text(reasons.isEmpty ? "Clearing the path ahead."
                 : "Tuned for " + reasons.map { $0.rawValue.lowercased() }.prefix(2).joined(separator: " & ") + ".")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.cream.opacity(0.5))
        }
        .task {
            for i in 0..<buildMessages.count {
                withAnimation(.smooth) { buildMsg = i }
                try? await Task.sleep(for: .seconds(0.7))
            }
            withAnimation(.smooth) {
                model.completeOnboarding(
                    quitDate: (lastUsed ?? .now).date,
                    weeklySpend: weeklySpend,
                    sessionsPerDay: (sessions ?? .few).perDay,
                    reasons: Array(reasons))
            }
        }
    }

    // MARK: Chrome

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.mint : Color.white.opacity(0.12))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .animation(.smooth, value: step)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            PillButton(title: step == totalSteps - 1 ? "Start my plan" : "Continue") {
                advance()
            }
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.4)

            if step > 0 {
                Button("Back") { withAnimation(.smooth) { step -= 1 } }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.cream.opacity(0.5))
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1: lastUsed != nil
        case 3: sessions != nil
        default: true
        }
    }

    private func advance() {
        if step == totalSteps - 1 {
            withAnimation(.smooth) { building = true }
        } else {
            withAnimation(.smooth) { step += 1 }
        }
    }
}

// MARK: - Onboarding option types

enum LastUsed: CaseIterable, Identifiable {
    case now, earlierToday, yesterday, fewDays, aboutWeek
    var id: Self { self }
    var label: String {
        switch self {
        case .now: "Just now — starting fresh"
        case .earlierToday: "Earlier today"
        case .yesterday: "Yesterday"
        case .fewDays: "A few days ago"
        case .aboutWeek: "About a week ago"
        }
    }
    var date: Date {
        let now = Date()
        switch self {
        case .now: return now
        case .earlierToday: return now.addingTimeInterval(-6 * 3600)
        case .yesterday: return now.addingTimeInterval(-24 * 3600)
        case .fewDays: return now.addingTimeInterval(-3 * 86_400)
        case .aboutWeek: return now.addingTimeInterval(-7 * 86_400)
        }
    }
}

enum SessionFrequency: CaseIterable, Identifiable {
    case once, few, many, allDay
    var id: Self { self }
    var label: String {
        switch self {
        case .once: "Once a day"
        case .few: "A few times a day"
        case .many: "Many times a day"
        case .allDay: "Pretty much all day"
        }
    }
    var perDay: Double {
        switch self {
        case .once: 1
        case .few: 3
        case .many: 6
        case .allDay: 10
        }
    }
}

// MARK: - Small shared onboarding views

private struct ProjectionRow: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.cream)
                Text(detail)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.cream.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
    }
}

private struct QuestionScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.cream)
            Text(subtitle)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.cream.opacity(0.55))
                .padding(.bottom, 8)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectRow: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(Theme.rounded(17, .medium))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Theme.mint : Theme.cream.opacity(0.25))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(selected ? 0.10 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Theme.mint.opacity(0.6) : .white.opacity(0.08), lineWidth: 1))
            )
        }
        .buttonStyle(PressableStyle())
    }
}
