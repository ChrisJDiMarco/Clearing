import SwiftUI

/// The daily anchor: cannabis-free time, a calm object to return to,
/// and two obvious actions. Supporting detail lives below the first viewport.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var showSettings: Bool
    var onDebugCelebrate: () -> Void = {}
    var onSupport: () -> Void = {}
    var onUsePlan: () -> Void = {}

    @State private var showSlipDialog = false
    @State private var showExitPlan = false
    @State private var showCheckInChoices = false
    @State private var showSymptomPrompt = false
    @State private var confirmUse = false
    @State private var selectedStat: StatInsight?
    @State private var showMilestoneExplorer = false

    var body: some View {
        ZStack {
            let now = Date()
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 0)
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        hero(now: context.date)
                    }
                    checkInSection
                        .padding(.top, 12)
                    supportButton
                        .padding(.top, 10)
                    exitPlanCard
                        .padding(.top, 24)
                    dailyBriefCard(now: now)
                        .padding(.top, 14)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        statRow(now: context.date)
                    }
                    .padding(.top, 12)
                    weeklyReportCard(now: now)
                        .padding(.top, 14)
                    nextMilestoneCard(now: now)
                        .padding(.top, 14)
                    #if DEBUG
                    debugRow
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showSlipDialog) {
            SlipReflectionSheet { trigger, guardrail in
                Haptics.soft()
                model.updateLatestSlipReflection(trigger: trigger, guardrail: guardrail)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExitPlan) {
            ExitPlanSheet(existing: model.exitPlan) { cue, need, action in
                model.setExitPlan(cue: cue, need: need, action: action)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedStat) { stat in
            StatInsightSheet(stat: stat)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMilestoneExplorer) {
            MilestoneExplorerSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Record cannabis use today?", isPresented: $confirmUse) {
            Button("Record use") { saveCheckIn(.used) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This updates your current clear stretch. You can add a note afterward if you want.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Today")
                .font(.system(size: 36, weight: .regular, design: .serif))
                .tracking(-1.5)
                .foregroundStyle(Theme.ink)
            Spacer()
            Button {
                Haptics.soft()
                showSettings = true
            } label: {
                ProfileOutline()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: Hero number

    private func dailyBriefCard(now: Date) -> some View {
        let brief = model.dailyBrief(asOf: now)
        let tint = brief.tint == "gold" ? Theme.gold : Theme.mint
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 42, height: 42)
                Image(systemName: brief.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(brief.title)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.cream)
                Text(brief.body)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.cream.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 24, glow: model.isRiskWindow(asOf: now)))
    }

    private func hero(now: Date) -> some View {
        let days = model.daysClean(asOf: now)
        let hours = Int(model.secondsClean(asOf: now) / 3600)
        return VStack(spacing: 0) {
            Text(days > 0 ? "\(days)" : hours > 0 ? "\(hours)" : "Now")
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 72 : (hours == 0 && days == 0 ? 90 : 108), weight: .regular, design: .serif))
                .tracking(-5)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(.snappy, value: days)
                .accessibilityLabel(days > 0 ? "\(days) days since last reported use" : hours > 0 ? "\(hours) hours since last reported use" : "A new clear stretch starts now")
            Text(days > 0 ? (days == 1 ? "day clear" : "days clear")
                 : hours > 0 ? (hours == 1 ? "hour clear" : "hours clear")
                 : "is enough.")
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 28 : 34, weight: .regular, design: .serif))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .padding(.top, -17)

            CrystalArtView(name: "ReferenceCrystalHero")
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 150 : 225)
                .padding(.top, 0)

            Text("One day at a time.")
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 19 : 23, weight: .regular, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 1)
            Button {
                Haptics.soft()
                showMilestoneExplorer = true
            } label: {
                Text("Explore milestones  ↗")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Stats

    private func statRow(now: Date) -> some View {
        HStack(spacing: 12) {
            Button { selectedStat = .money } label: {
                InspectableStatTile(icon: "banknote.fill",
                                    value: model.moneySaved(asOf: now).asMoneyLive,
                                    label: "est. saved")
            }
            Button { selectedStat = .sessions } label: {
                InspectableStatTile(icon: "leaf.arrow.triangle.circlepath",
                                    value: "\(Int(model.sessionsAvoided(asOf: now)))",
                                    label: "est. sessions")
            }
            Button { selectedStat = .hours } label: {
                InspectableStatTile(icon: "clock.arrow.circlepath",
                                    value: "\(Int(model.hoursReclaimed(asOf: now)))h",
                                    label: "est. time")
            }
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Check-in

    private var checkInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let checkIn = model.todayCheckIn, !showCheckInChoices {
                HStack(spacing: 12) {
                    Image(systemName: checkIn.status == .clear ? "checkmark.circle.fill" : "heart.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.paper)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(checkIn.status == .clear ? "Clear so far today" : "Today is recorded")
                            .font(.system(size: 16, weight: .semibold))
                        Text(checkIn.status == .clear ? "Keep taking it one moment at a time." : "One day does not define your progress.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.paper.opacity(0.72))
                    }
                    Spacer(minLength: 4)
                    if checkIn.status == .clear {
                        Button("Update") {
                            Haptics.soft()
                            withAnimation(.easeInOut(duration: 0.2)) { showCheckInChoices = true }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.paper.opacity(0.82))
                        .accessibilityLabel("Update today's check-in")
                    }
                }
                .foregroundStyle(Theme.paper)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 17)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.ink))

                if checkIn.status == .used {
                    Button {
                        Haptics.soft()
                        showSlipDialog = true
                    } label: {
                        Label("Add a note for next time", systemImage: "square.and.pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.mutedInk)
                    }
                    .padding(.leading, 4)
                }
            } else {
                Text("How is today going?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
                    .padding(.leading, 4)
                HStack(spacing: 10) {
                    checkInChoice("Clear so far", icon: "checkmark", status: .clear, filled: true)
                    checkInChoice("I used", icon: "heart", status: .used, filled: false)
                }
                if model.todayCheckIn != nil {
                    Button("Keep current answer") {
                        withAnimation(.easeInOut(duration: 0.2)) { showCheckInChoices = false }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.mutedInk)
                    .frame(maxWidth: .infinity)
                }
            }

            if showSymptomPrompt, let checkIn = model.todayCheckIn {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Anything difficult today?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.2)) { showSymptomPrompt = false }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.mutedInk)
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(["Sleep", "Mood", "Appetite", "Cravings"], id: \.self) { symptom in
                            Button {
                                Haptics.soft()
                                model.recordCheckIn(checkIn.status, symptom: symptom)
                                withAnimation(.easeInOut(duration: 0.2)) { showSymptomPrompt = false }
                            } label: {
                                Chip(title: symptom, selected: false)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                .padding(16)
                .background(GlassCard(cornerRadius: 20))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func checkInChoice(_ title: String, icon: String, status: UseStatus, filled: Bool) -> some View {
        Button {
            if status == .used {
                Haptics.soft()
                confirmUse = true
            } else {
                saveCheckIn(.clear)
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(filled ? Theme.paper : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 19)
                .background(Capsule().fill(filled ? Theme.ink : Theme.paper))
                .overlay(Capsule().strokeBorder(filled ? Theme.ink : Theme.ink.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private func saveCheckIn(_ status: UseStatus) {
        if status == .clear { Haptics.success() } else { Haptics.soft() }
        model.recordCheckIn(status)
        withAnimation(.easeInOut(duration: 0.2)) {
            showCheckInChoices = false
            showSymptomPrompt = true
        }
    }

    private var supportButton: some View {
        Button {
            Haptics.rigid()
            onSupport()
        } label: {
            Text("I need support")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 21)
                .background(Capsule().strokeBorder(Theme.ink.opacity(0.42), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var exitPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.amberInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.amberLight.opacity(0.42)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your exit")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(model.exitPlan == nil ? "One small move for a hard moment." : "A plan you can actually use.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.mutedInk)
                }
                Spacer(minLength: 0)
                if model.exitPlan != nil {
                    Button {
                        Haptics.soft()
                        showExitPlan = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.mutedInk)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Edit your exit plan")
                }
            }

            if let plan = model.exitPlan {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(plan.cue.uppercased()) · \(plan.need.uppercased())")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.amberInk)
                    Text(plan.action)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    Haptics.rigid()
                    onUsePlan()
                } label: {
                    HStack {
                        Text("Use this plan now")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 3)
                }
            } else {
                Button {
                    Haptics.soft()
                    showExitPlan = true
                } label: {
                    HStack {
                        Text("Make my plan")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(18)
        .background(GlassCard(cornerRadius: 24))
    }

    // MARK: Next milestone

    private func weeklyReportCard(now: Date) -> some View {
        let report = model.weeklyReport(asOf: now)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text(report.title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Label(report.urges > 0
                      ? "Support: \(report.hardestWindow.shortLabel)"
                      : "Plan: \(report.hardestWindow.shortLabel)",
                      systemImage: report.hardestWindow.icon)
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(Theme.gold)
            }
            Text(report.body)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.cream.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                MiniMetric(value: report.money, label: "est. saved")
                MiniMetric(value: "\(report.urges)", label: "support opens")
                MiniMetric(value: "\(report.checkIns)/7", label: "check-ins")
            }
        }
        .padding(18)
        .background(GlassCard(cornerRadius: 24))
    }

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
                    Text("When you reach this marker, pause and notice what helped you get there.")
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
                    Text("You have reached the last guidepost shown here. Your own progress continues beyond it.")
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

private struct ProfileOutline: View {
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .strokeBorder(Theme.ink, lineWidth: 1.4)
                Circle()
                    .strokeBorder(Theme.ink, lineWidth: 1.3)
                    .frame(width: side * 0.25, height: side * 0.25)
                    .offset(y: -side * 0.15)
                Path { path in
                    path.move(to: CGPoint(x: side * 0.23, y: side * 0.81))
                    path.addQuadCurve(to: CGPoint(x: side * 0.77, y: side * 0.81),
                                      control: CGPoint(x: side * 0.50, y: side * 0.43))
                }
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct InspectableStatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        StatTile(icon: icon, value: value, label: label)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.22))
                    .padding(10)
            }
    }
}

private struct MiniMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Theme.rounded(10, .semibold))
                .foregroundStyle(Theme.cream.opacity(0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1))
        )
    }
}

private enum StatInsight: String, Identifiable {
    case money, sessions, hours
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .money: "banknote.fill"
        case .sessions: "leaf.arrow.triangle.circlepath"
        case .hours: "clock.arrow.circlepath"
        }
    }

    var title: String {
        switch self {
        case .money: "Estimated unspent"
        case .sessions: "Estimated sessions skipped"
        case .hours: "Estimated time reclaimed"
        }
    }
}

private struct StatInsightSheet: View {
    @Environment(AppModel.self) private var model
    let stat: StatInsight

    var body: some View {
        let now = Date()
        let sheetRows = rows(asOf: now)
        ZStack {
            AmbientBackground(progress: model.dawnProgress(asOf: now))
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: stat.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.mint)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.mint.opacity(0.14)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stat.title)
                            .font(Theme.rounded(24, .bold))
                            .foregroundStyle(Theme.cream)
                        Text(primaryValue(asOf: now))
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.brightMint)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(sheetRows.enumerated()), id: \.element.0) { index, row in
                        HStack {
                            Text(row.0)
                                .font(Theme.rounded(14, .medium))
                                .foregroundStyle(Theme.cream.opacity(0.58))
                            Spacer()
                            Text(row.1)
                                .font(Theme.rounded(14, .bold))
                                .foregroundStyle(Theme.cream)
                        }
                        .padding(.vertical, 12)
                        if index < sheetRows.count - 1 {
                            Divider().overlay(.white.opacity(0.08))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(GlassCard(cornerRadius: 22))

                Text(explainer)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.cream.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
        }
    }

    private func primaryValue(asOf now: Date) -> String {
        switch stat {
        case .money: model.moneySaved(asOf: now).asMoneyLive
        case .sessions: "About \(Int(model.sessionsAvoided(asOf: now))) sessions"
        case .hours: "About \(Int(model.hoursReclaimed(asOf: now))) hours"
        }
    }

    private func rows(asOf now: Date) -> [(String, String)] {
        let estimatedDays = model.estimatedClearSeconds(asOf: now) / 86_400
        switch stat {
        case .money:
            return [("Weekly baseline", model.data.weeklySpend.asMoney),
                    ("Daily rate", (model.data.weeklySpend / 7).asMoney),
                    ("Days counted", "\(String(format: "%.1f", estimatedDays)) estimated")]
        case .sessions:
            return [("Daily baseline", "\(String(format: "%.1f", model.data.sessionsPerDay))"),
                    ("Days counted", "\(String(format: "%.1f", estimatedDays)) estimated"),
                    ("Current stretch", "\(model.daysClean(asOf: now)) days")]
        case .hours:
            return [("Session estimate", "30 minutes"),
                    ("Est. sessions avoided", "\(Int(model.sessionsAvoided(asOf: now)))"),
                    ("Days counted", "\(String(format: "%.1f", estimatedDays)) estimated")]
        }
    }

    private var explainer: String {
        switch stat {
        case .money: "An estimate since you began, based on your weekly spending. Days with reported use are excluded. It is not your actual bank balance; adjust the baseline in Settings."
        case .sessions: "An estimate since you began, using the daily baseline you entered. Days with reported use are excluded."
        case .hours: "An estimate since you began, using 30 minutes per session and excluding days with reported use."
        }
    }
}

private struct MilestoneExplorerSheet: View {
    @Environment(AppModel.self) private var model
    @State private var previewDay: Double?

    var body: some View {
        let current = model.fractionalDaysClean()
        let day = previewDay ?? current
        let milestone = Milestones.all.first { $0.day >= day } ?? Milestones.all.last
        ZStack {
            AmbientBackground(progress: min(1, day / 30))
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery preview")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.cream)
                    Text("Day \(Int(day))")
                        .font(.system(size: 58, weight: .semibold, design: .serif))
                        .fontWidth(.condensed)
                        .foregroundStyle(Theme.cream)
                        .monospacedDigit()
                }

                Slider(value: Binding(get: {
                    previewDay ?? current
                }, set: { value in
                    previewDay = value
                }), in: 0...90, step: 0.5)
                .tint(Theme.mint)

                if let milestone {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: milestone.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Theme.gold.opacity(0.13)))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(milestone.title)
                                .font(Theme.rounded(17, .bold))
                                .foregroundStyle(Theme.cream)
                            Text(milestone.fact)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.cream.opacity(0.58))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(GlassCard(cornerRadius: 22))
                }

                Button {
                    Haptics.soft()
                    previewDay = current
                } label: {
                    Text("Back to today")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.mint)
                }
            }
            .padding(22)
        }
    }
}

private struct SlipReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void

    @State private var trigger = ""
    @State private var guardrail = ""

    private let triggers = ["Stress", "Boredom", "Sleep", "Social", "Pain", "Easy access"]
    private let guardrails = ["Leave the room", "Text someone", "Walk 10 minutes", "Take a shower", "Put it out of reach", "Use my exit plan"]

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("A note for next time")
                            .font(.system(size: 29, weight: .regular, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Today is already recorded. If it helps, notice one pattern and choose one next move.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    picker(title: "What was happening?", options: triggers, selection: $trigger)
                    picker(title: "What could help next time?", options: guardrails, selection: $guardrail)

                    Button {
                        onSave(trigger, guardrail)
                        dismiss()
                    } label: {
                        Text("Save note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Capsule().fill(Theme.ink))
                    }
                    .disabled(trigger.isEmpty && guardrail.isEmpty)
                    .opacity(trigger.isEmpty && guardrail.isEmpty ? 0.45 : 1)

                    Button("Not now") { dismiss() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.mutedInk)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
        }
    }

    private func picker(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Theme.mutedInk)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        Haptics.soft()
                        selection.wrappedValue = option
                    } label: {
                        Chip(title: option, selected: selection.wrappedValue == option)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }
}

private struct ExitPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, String) -> Void

    @State private var cue: String
    @State private var need: String
    @State private var action: String

    private let cues = ["After work", "Before bed", "When stressed", "When alone", "When bored", "With friends"]
    private let needs = ["Unwind", "Sleep", "Relief", "Reward", "Connection", "Something to do"]
    private let actions = ["Leave the room", "Take a walk", "Take a shower", "Text someone", "Put supplies away", "Make tea"]

    init(existing: ExitPlan?, onSave: @escaping (String, String, String) -> Void) {
        self.onSave = onSave
        _cue = State(initialValue: existing?.cue ?? "")
        _need = State(initialValue: existing?.need ?? "")
        _action = State(initialValue: existing?.action ?? "")
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Your exit")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Make one small plan while things are calm. You can change it whenever you learn what works.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    planField(number: "01", title: "When do you reach for it?", options: cues,
                              text: $cue, placeholder: "Or describe your own moment")
                    planField(number: "02", title: "What are you looking for?", options: needs,
                              text: $need, placeholder: "Or name what you need")
                    planField(number: "03", title: "What will you do first?", options: actions,
                              text: $action, placeholder: "Or choose one concrete move")

                    Button {
                        Haptics.success()
                        onSave(cue, need, action)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Save my exit")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 19)
                        .background(Capsule().fill(Theme.ink))
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)

                    Text("A plan is a prompt, not a test. Change course whenever you need to.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.mutedInk)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var canSave: Bool {
        [cue, need, action].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func planField(number: String, title: String, options: [String],
                           text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(number)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.amberInk)
                Text(title)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            FlowLayout(spacing: 7) {
                ForEach(options, id: \.self) { option in
                    Button {
                        Haptics.soft()
                        text.wrappedValue = option
                    } label: {
                        Chip(title: option, selected: text.wrappedValue == option)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.paper))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1))
        }
    }
}
