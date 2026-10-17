import SwiftUI

/// A gentle setup for a private cannabis-quitting plan. The welcome screen
/// establishes the visual language, then the questions personalize support.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    @State private var step = 0
    @State private var lastUsed: LastUsed? = nil
    @State private var weeklySpend: Double = 45
    @State private var sessions: SessionFrequency? = nil
    @State private var riskWindow: RiskWindow? = nil
    @State private var reasons: Set<Reason> = []
    @State private var building = false
    @State private var buildMsg = 0

    private let totalSteps = 7
    private let buildMessages = ["Reading your patterns…", "Mapping your recovery timeline…", "Tuning your plan…"]

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            if building {
                buildingView
            } else {
                VStack(spacing: 0) {
                    progressBar
                    ScrollView {
                        content
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: step == 0 ? 610 : 500)
                            .padding(.horizontal, 28)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)))
                            .id(step)
                    }
                    .scrollIndicators(.hidden)
                    footer
                        .padding(.horizontal, 28)
                        .padding(.bottom, 16)
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
                riskWindow = .evening
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
        case 4: riskWindowStep
        case 5: reasonsStep
        default: projectionStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)
            crystalArtwork
                .frame(height: 360)
                .scaleEffect(1.18)

            Text("Make room\nfor more.")
                .font(.system(size: 52, weight: .regular, design: .serif))
                .tracking(-1.5)
                .lineSpacing(-5)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            Text("A private place to quit cannabis,\none day at a time.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Theme.mutedInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Spacer(minLength: 30)
        }
    }

    private var crystalArtwork: some View {
        CrystalArtView(name: "OnboardingCrystalHero")
            .frame(height: 360)
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
                    .font(.system(size: 42, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Slider(value: $weeklySpend, in: 10...250, step: 5)
                    .tint(Theme.amberInk)
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

    private var riskWindowStep: some View {
        QuestionScaffold(title: "When is it hardest?",
                         subtitle: "Choose the closest fit. You can change it later; urges don't follow a perfect schedule.") {
            VStack(spacing: 12) {
                ForEach(RiskWindow.allCases) { option in
                    SelectRow(title: option.label, icon: option.icon, selected: riskWindow == option) {
                        riskWindow = option
                    }
                }
            }
        }
    }

    private var reasonsStep: some View {
        QuestionScaffold(title: "Why now?",
                         subtitle: "Pick what matters. We'll keep it close when you need support.") {
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
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("A few possibilities—not promises. Your experience will be your own.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.cream.opacity(0.55))
            }

            VStack(spacing: 0) {
                ProjectionRow(icon: "banknote.fill",
                              title: "About " + (weeklySpend * 52).asMoney + " less spent",
                              detail: "in a year at the weekly amount you entered", tint: Theme.mint)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "moon.stars.fill",
                              title: "Make room for rest",
                              detail: "your sleep can change as you adjust", tint: Theme.amberInk)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "sparkles",
                              title: "Notice what returns",
                              detail: "more space for your own thoughts", tint: Theme.amberInk)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: (riskWindow ?? .evening).icon,
                              title: (riskWindow ?? .evening).label,
                              detail: riskWindow == .throughoutDay
                                ? "your plan can be there whenever you need it"
                                : "a time to keep your exit plan close", tint: Theme.brightMint)
                Divider().overlay(.white.opacity(0.08))
                ProjectionRow(icon: "leaf.fill",
                              title: "Build a new rhythm",
                              detail: "one cannabis-free day at a time", tint: Theme.amberInk)
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
                    reasons: Array(reasons),
                    riskWindow: riskWindow)
            }
        }
    }

    // MARK: Chrome

    private var progressBar: some View {
        VStack(spacing: 18) {
            if step == 0 {
                VStack(spacing: 6) {
                    Text("Clearing")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .tracking(-2)
                        .foregroundStyle(Theme.ink)
                    Text("S P A C E   T O   C H A N G E")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.mutedInk)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
            } else {
                HStack {
                    Text("Clearing")
                        .font(.system(size: 25, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(String(format: "%02d  /  %02d", step + 1, totalSteps))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.mutedInk)
                }
                HStack(spacing: 5) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Theme.ink : Theme.ink.opacity(0.11))
                            .frame(height: 3)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .animation(.smooth, value: step)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            PillButton(title: step == 0 ? "Begin" : (step == totalSteps - 1 ? "Start my plan" : "Continue"),
                       trailingIcon: step == 0 ? "arrow.right" : nil) {
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
        .padding(.bottom, 10)
    }

    private var canAdvance: Bool {
        switch step {
        case 1: lastUsed != nil
        case 3: sessions != nil
        case 4: riskWindow != nil
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

private struct WelcomeTimelineCard: View {
    var body: some View {
        HStack(spacing: 10) {
            WelcomeSignal(icon: "sunrise.fill", title: "Day 1", detail: "begin")
            Divider()
                .frame(height: 44)
                .overlay(Theme.deepGreen.opacity(0.10))
            WelcomeSignal(icon: "sparkles", title: "Day 7", detail: "notice")
            Divider()
                .frame(height: 44)
                .overlay(Theme.deepGreen.opacity(0.10))
            WelcomeSignal(icon: "leaf.fill", title: "Day 30", detail: "continue")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(GlassCard(cornerRadius: 26, glow: true))
    }
}

private struct WelcomeSignal: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.mint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.mint.opacity(0.12)))
            Text(title)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail.uppercased())
                .font(Theme.rounded(10, .bold))
                .foregroundStyle(Theme.cream.opacity(0.42))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct QuestionScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 38, weight: .regular, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.mutedInk)
                .padding(.bottom, 18)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectRow: View {
    let title: String
    var icon: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected ? Theme.mint : Theme.cream.opacity(0.35))
                        .frame(width: 24)
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Theme.amberInk : Theme.mutedInk.opacity(0.45))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? Theme.amberInk.opacity(0.65) : Theme.hairline, lineWidth: 1))
            )
        }
        .buttonStyle(PressableStyle())
    }
}
