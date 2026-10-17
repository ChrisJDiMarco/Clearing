import Foundation
import Observation

/// Observable store. Persists `QuitData` to UserDefaults on every change and
/// exposes all derived metrics the UI renders.
@Observable
final class AppModel {
    var data: QuitData {
        didSet { save() }
    }

    private let key = "clearing.quitdata.v1"

    init() {
        #if DEBUG
        if Demo.seed {
            data = Demo.seededData()   // property observers don't run in init → not persisted
            return
        }
        #endif
        if let raw = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(QuitData.self, from: raw) {
            data = decoded
        } else {
            data = .empty
        }
    }

    private func save() {
        #if DEBUG
        if Demo.seed { return }   // demo seed stays ephemeral — never pollute a real launch
        #endif
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: key)
        }
        WidgetSync.write(.init(cleanStart: cleanStart,
                               weeklySpend: data.weeklySpend,
                               sessionsPerDay: data.sessionsPerDay,
                               riskWindow: selectedRiskWindow().rawValue))
    }

    // MARK: - Derived metrics

    /// Current clean streak starts at the quit date, or the most recent slip.
    var cleanStart: Date {
        max(data.quitDate, data.slips.max() ?? data.quitDate)
    }

    func secondsClean(asOf now: Date = Date()) -> Double {
        max(0, now.timeIntervalSince(cleanStart))
    }

    func daysClean(asOf now: Date = Date()) -> Int {
        Int(secondsClean(asOf: now) / 86_400)
    }

    func fractionalDaysClean(asOf now: Date = Date()) -> Double {
        secondsClean(asOf: now) / 86_400
    }

    /// The longest uninterrupted stretch since the chosen quit date. This is
    /// historical context only; the live streak and next milestone still use
    /// `cleanStart` after a reported use.
    func longestClearStretchSeconds(asOf now: Date = Date()) -> Double {
        guard now > data.quitDate else { return 0 }
        var stretchStart = data.quitDate
        var longest = 0.0
        for useDate in data.slips.filter({ $0 >= data.quitDate && $0 <= now }).sorted() {
            longest = max(longest, useDate.timeIntervalSince(stretchStart))
            stretchStart = useDate
        }
        return max(longest, now.timeIntervalSince(stretchStart))
    }

    func longestClearStretchDays(asOf now: Date = Date()) -> Double {
        longestClearStretchSeconds(asOf: now) / 86_400
    }

    /// Conservative cumulative estimate, not a verified spend/use ledger.
    /// Any reported-use day contributes zero estimated savings, even if there
    /// were clear hours on that day. Distinct local calendar days are counted
    /// once and their actual (DST-aware) durations are intersected with the
    /// requested interval.
    static func estimatedClearSeconds(quitDate: Date, periodStart: Date,
                                      asOf now: Date, useEvents: [Date],
                                      calendar: Calendar = .current) -> Double {
        let start = max(quitDate, periodStart)
        guard now > start else { return 0 }
        let usedDayStarts = Set(useEvents.filter { $0 >= quitDate && $0 <= now }
            .map { calendar.startOfDay(for: $0) })
        let usedSeconds = usedDayStarts.reduce(0.0) { total, dayStart in
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return total }
            return total + max(0, min(now, nextDay).timeIntervalSince(max(start, dayStart)))
        }
        return max(0, now.timeIntervalSince(start) - usedSeconds)
    }

    func estimatedClearSeconds(asOf now: Date = Date()) -> Double {
        Self.estimatedClearSeconds(quitDate: data.quitDate, periodStart: data.quitDate,
                                   asOf: now, useEvents: data.slips)
    }

    func moneySaved(asOf now: Date = Date()) -> Double {
        data.weeklySpend / (7 * 86_400) * estimatedClearSeconds(asOf: now)
    }

    func sessionsAvoided(asOf now: Date = Date()) -> Double {
        data.sessionsPerDay * (estimatedClearSeconds(asOf: now) / 86_400)
    }

    func hoursReclaimed(asOf now: Date = Date()) -> Double {
        sessionsAvoided(asOf: now) * 0.5
    }

    /// Visual continuity since starting; not a biological recovery indicator.
    func dawnProgress(asOf now: Date = Date()) -> Double {
        min(1, max(0, now.timeIntervalSince(data.quitDate)) / (30 * 86_400))
    }

    // MARK: - Insight layer

    func selectedRiskWindow() -> RiskWindow {
        RiskWindow.from(data.riskWindow) ?? inferredRiskWindow()
    }

    func primaryReason() -> String {
        data.reasons.first ?? Reason.control.rawValue
    }

    func isRiskWindow(asOf now: Date = Date()) -> Bool {
        let window = selectedRiskWindow()
        if window == .throughoutDay { return false }
        let hour = Calendar.current.component(.hour, from: now)
        let end = (window.startHour + 4) % 24
        if window.startHour < end {
            return hour >= window.startHour && hour < end
        }
        return hour >= window.startHour || hour < end
    }

    func dailyBrief(asOf now: Date = Date()) -> DailyBrief {
        if let slip = data.slipReflections.last, now.timeIntervalSince(slip.date) < 36 * 3600 {
            let hasPersonalStep = slip.guardrail != "Choose one next step that could help."
            return DailyBrief(icon: "arrow.counterclockwise",
                              title: "A new moment is here",
                              body: hasPersonalStep ? "Your next step: \(slip.guardrail)" : "No explanation needed. Your support and exit plan are here when you want them.",
                              tint: "gold")
        }
        if let pending = pendingCelebration(asOf: now) {
            return DailyBrief(icon: pending.icon,
                              title: "\(pending.badge) is ready",
                              body: "Open the milestone and let the win land.",
                              tint: "gold")
        }
        if let urge = data.urgesBeaten.last, now.timeIntervalSince(urge) < 30 * 60 {
            return DailyBrief(icon: "wind.circle.fill",
                              title: "You checked back in",
                              body: "Notice what helped, even a little. Keep your next step simple.",
                              tint: "mint")
        }
        let cleanHours = Int(secondsClean(asOf: now) / 3600)
        if fractionalDaysClean(asOf: now) < 1 {
            return DailyBrief(icon: "sunrise.fill",
                              title: cleanHours == 0 ? "This hour is yours" : cleanHours == 1 ? "First clear hour" : "\(cleanHours) clear hours",
                              body: "You only need to choose your next step, not solve the whole month.",
                              tint: "mint")
        }
        if isRiskWindow(asOf: now) {
            return DailyBrief(icon: selectedRiskWindow().icon,
                              title: "Your \(selectedRiskWindow().shortLabel) window is live",
                              body: "Make the next hour boring: water, distance, one clean replacement.",
                              tint: "mint")
        }
        if !hasCheckedInToday {
            return DailyBrief(icon: "checkmark.seal.fill",
                              title: "How was today?",
                              body: "An honest check-in helps you see your pattern. No perfect answer needed.",
                              tint: "mint")
        }
        if daysClean(asOf: now) == 1 {
            return DailyBrief(icon: "checkmark.seal.fill",
                              title: "Day 1 is protected",
                              body: "Early days are built in quiet moves. Keep today simple.",
                              tint: "mint")
        }
        let sessions = Int(sessionsAvoided(asOf: now))
        let hours = Int(hoursReclaimed(asOf: now))
        let body = sessions == 0 && hours == 0
            ? "Keep this hour simple: water, distance, one clean replacement."
            : "Estimated since you began: about \(sessions) sessions and \(hours) hours reclaimed."
        return DailyBrief(icon: "leaf.fill",
                          title: "Steady day",
                          body: body,
                          tint: "mint")
    }

    func weeklyReport(asOf now: Date = Date()) -> WeeklyReport {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now.addingTimeInterval(-7 * 86_400)
        let recentUrges = data.urgeStarts.filter { $0 >= start && $0 <= now }.count
        let recentCheckInDays = Set((data.checkIns.filter { $0 >= start && $0 <= now }
            + data.dailyCheckIns.map(\.date).filter { $0 >= start && $0 <= now })
            .map { Calendar.current.startOfDay(for: $0) })
        let recentCheckIns = min(7, recentCheckInDays.count)
        let recentSlips = data.slips.filter { $0 >= start && $0 <= now }.count
        let clearCheckIns = data.dailyCheckIns.filter { $0.date >= start && $0.date <= now && $0.status == .clear }.count
        let estimatedSeconds = Self.estimatedClearSeconds(quitDate: data.quitDate,
            periodStart: start, asOf: now, useEvents: data.slips)
        let money = data.weeklySpend / (7 * 86_400) * estimatedSeconds
        let hardest = hardestWindow(asOf: now)
        let body = recentSlips > 0
            ? "\(recentSlips) use event\(recentSlips == 1 ? "" : "s") logged. What could help next time?"
            : clearCheckIns > 0
                ? "\(clearCheckIns) clear day\(clearCheckIns == 1 ? "" : "s") recorded. Keep noticing what helps."
                : "No use reported this week. Check in to see your own pattern."
        return WeeklyReport(title: "7-day report",
                            money: money.asMoney,
                            urges: recentUrges,
                            checkIns: recentCheckIns,
                            hardestWindow: hardest,
                            body: body)
    }

    func recoverySystems(asOf now: Date = Date()) -> [RecoverySystem] {
        let days = fractionalDaysClean(asOf: now)
        func progress(_ target: Double) -> Double { min(1, max(0, days / target)) }
        return [
            RecoverySystem(id: "sleep", icon: "moon.stars.fill", title: "Week 1 reflection", detail: "How has sleep felt for you?", progress: progress(7)),
            RecoverySystem(id: "clarity", icon: "sparkles", title: "Week 2 reflection", detail: "What has helped you focus?", progress: progress(14)),
            RecoverySystem(id: "mood", icon: "heart.fill", title: "Week 3 reflection", detail: "What helps when feelings shift?", progress: progress(21)),
            RecoverySystem(id: "body", icon: "figure.walk", title: "Month 1 reflection", detail: "What do you notice in your body?", progress: progress(30)),
            RecoverySystem(id: "patterns", icon: "leaf.fill", title: "Day 90 reflection", detail: "Which choices are worth keeping?", progress: progress(90)),
        ]
    }

    func cravingHeatmap(asOf now: Date = Date()) -> [HeatmapBucket] {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now.addingTimeInterval(-30 * 86_400)
        let events = data.urgeStarts.filter { $0 >= start && $0 <= now }
        let counts = Dictionary(grouping: events, by: window(for:)).mapValues(\.count)
        let maxCount = max(1, counts.values.max() ?? 0)
        return RiskWindow.clockWindows.map { window in
            HeatmapBucket(window: window, count: counts[window, default: 0], peak: counts[window, default: 0] == maxCount && maxCount > 0)
        }
    }

    // MARK: - Milestones

    func reachedMilestones(asOf now: Date = Date()) -> [Milestone] {
        let days = fractionalDaysClean(asOf: now)
        return Milestones.all.filter { $0.day <= days }
    }

    func nextMilestone(asOf now: Date = Date()) -> Milestone? {
        let days = fractionalDaysClean(asOf: now)
        return Milestones.all.first { $0.day > days }
    }

    /// Progress 0...1 toward the next milestone, for the hero progress arc.
    func progressToNextMilestone(asOf now: Date = Date()) -> Double {
        let days = fractionalDaysClean(asOf: now)
        let prev = reachedMilestones(asOf: now).last?.day ?? 0
        guard let next = nextMilestone(asOf: now)?.day else { return 1 }
        guard next > prev else { return 1 }
        return min(1, max(0, (days - prev) / (next - prev)))
    }

    /// A milestone the user just crossed but hasn't celebrated yet.
    func pendingCelebration(asOf now: Date = Date()) -> Milestone? {
        guard let latest = reachedMilestones(asOf: now).last else { return nil }
        return latest.day > data.lastCelebratedDay ? latest : nil
    }

    func markCelebrated(_ milestone: Milestone) {
        data.lastCelebratedDay = milestone.day
        AppEvents.log("milestone_celebrated", milestone.title)
    }

    // MARK: - Daily check-in

    var hasCheckedInToday: Bool {
        todayCheckIn != nil || data.checkIns.contains(where: Calendar.current.isDateInToday)
    }

    var todayCheckIn: DailyCheckIn? {
        data.dailyCheckIns.last { Calendar.current.isDateInToday($0.date) }
    }

    var exitPlan: ExitPlan? { data.exitPlan }

    func recordCheckIn(_ status: UseStatus, symptom: String? = nil) {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: now)
        let alreadyUsedToday = data.slips.contains { calendar.isDate($0, inSameDayAs: now) }
        let effectiveStatus: UseStatus = alreadyUsedToday ? .used : status
        let trimmedSymptom = symptom?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = data.dailyCheckIns.lastIndex(where: { calendar.isDate($0.date, inSameDayAs: now) }) {
            data.dailyCheckIns[index].status = effectiveStatus
            if let trimmedSymptom, !trimmedSymptom.isEmpty {
                data.dailyCheckIns[index].symptom = trimmedSymptom
            }
        } else {
            data.dailyCheckIns.append(DailyCheckIn(date: now, status: effectiveStatus,
                                                  symptom: trimmedSymptom?.isEmpty == false ? trimmedSymptom : nil))
        }
        if !data.checkIns.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
            data.checkIns.append(day)
        }
        if effectiveStatus == .used && !alreadyUsedToday {
            appendSlip(at: now, trigger: "Daily check-in", guardrail: "Choose one next step that could help.", deduplicateSameDay: true)
        }
        AppEvents.log("check_in", effectiveStatus.rawValue)
    }

    func checkIn() {
        let today = Calendar.current.startOfDay(for: Date())
        if !data.checkIns.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            let first = data.checkIns.isEmpty
            data.checkIns.append(today)
            AppEvents.log(first ? "first_check_in" : "check_in", "\(daysClean()) days")
        }
    }

    func isCheckedIn(on day: Date) -> Bool {
        data.checkIns.contains { Calendar.current.isDate($0, inSameDayAs: day) }
            || data.dailyCheckIns.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    // MARK: - Actions

    func logSlip(trigger: String = "Unlabeled trigger",
                 guardrail: String = "Open Urge Mode before the next session.") {
        appendSlip(at: Date(), trigger: trigger, guardrail: guardrail)
    }

    /// Add context to a use event without creating another use timestamp.
    func updateLatestSlipReflection(trigger: String, guardrail: String) {
        guard let slipDate = data.slips.max() else { return }
        let trigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let guardrail = guardrail.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = data.slipReflections.lastIndex(where: { abs($0.date.timeIntervalSince(slipDate)) < 10 * 60 }) {
            data.slipReflections[index].trigger = trigger.isEmpty ? "Unlabeled trigger" : trigger
            data.slipReflections[index].guardrail = guardrail.isEmpty ? "Choose one next step that could help." : guardrail
        } else {
            data.slipReflections.append(SlipReflection(date: slipDate,
                trigger: trigger.isEmpty ? "Unlabeled trigger" : trigger,
                guardrail: guardrail.isEmpty ? "Choose one next step that could help." : guardrail))
        }
        AppEvents.log("slip_reflection_updated")
    }

    func setExitPlan(cue: String, need: String, action: String) {
        let cue = cue.trimmingCharacters(in: .whitespacesAndNewlines)
        let need = need.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = action.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cue.isEmpty, !need.isEmpty, !action.isEmpty else { return }
        data.exitPlan = ExitPlan(cue: cue, need: need, action: action)
        AppEvents.log("exit_plan_saved")
    }

    func logUrgeStart(at date: Date = Date()) {
        if let last = data.urgeStarts.last, date.timeIntervalSince(last) < 5 * 60 { return }
        data.urgeStarts.append(date)
        AppEvents.log("urge_opened")
    }

    func beatUrge(action: String? = nil) {
        recordUrgeOutcome(.okay, need: "Not recorded", action: action ?? "Not recorded")
    }

    func recordUrgeOutcome(_ outcome: UrgeOutcome, need: String, action: String) {
        let now = Date()
        let need = need.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = action.trimmingCharacters(in: .whitespacesAndNewlines)
        if outcome != .stillWant, let index = data.urgeRecords.lastIndex(where: {
            $0.outcome == .stillWant
                && now.timeIntervalSince($0.date) >= 0 && now.timeIntervalSince($0.date) < 30 * 60
        }) {
            data.urgeRecords[index].outcome = outcome
            if !need.isEmpty { data.urgeRecords[index].need = need }
            if !action.isEmpty { data.urgeRecords[index].action = action }
        } else if let last = data.urgeRecords.last,
                  last.outcome == outcome && last.need == need && last.action == action,
                  now.timeIntervalSince(last.date) >= 0 && now.timeIntervalSince(last.date) < 2 * 60 {
            return
        } else {
            data.urgeRecords.append(UrgeRecord(date: now, need: need, action: action, outcome: outcome))
        }
        switch outcome {
        case .okay:
            data.urgesBeaten.append(now)
            AppEvents.log("urge_handled", action)
        case .stillWant:
            AppEvents.log("urge_still_present")
        case .used:
            appendSlip(at: now, trigger: need.isEmpty ? "Support session" : need,
                       guardrail: "Choose one next step that could help.")
            AppEvents.log("urge_ended_in_use")
        }
    }

    var urgesBeaten: Int { data.urgesBeaten.count }

    func completeOnboarding(quitDate: Date, weeklySpend: Double,
                            sessionsPerDay: Double, reasons: [Reason],
                            riskWindow: RiskWindow? = nil) {
        data.quitDate = quitDate
        data.weeklySpend = weeklySpend
        data.sessionsPerDay = sessionsPerDay
        data.reasons = reasons.map(\.rawValue)
        data.riskWindow = riskWindow?.rawValue
        // Reminders are optional; the Settings toggle requests permission.
        data.remindersEnabled = false
        data.hasOnboarded = true
        AppEvents.log("onboarding_completed", riskWindow?.rawValue ?? "inferred")
    }

    /// Schedule or clear local reminders to match the current state.
    func refreshReminders() {
        if data.remindersEnabled {
            Reminders.schedule(cleanStart: cleanStart, dailyHour: selectedRiskWindow().startHour)
        } else {
            Reminders.cancelAll()
        }
    }

    func resetAll() {
        data = .empty
    }

    #if DEBUG
    /// Backdate the quit date so screenshots/demos show a meaningful streak.
    func debugBackdate(days: Int) {
        data.quitDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? data.quitDate
        data.lastCelebratedDay = 0
    }
    #endif

    private func hardestWindow(asOf now: Date = Date()) -> RiskWindow {
        let buckets = cravingHeatmap(asOf: now)
        guard buckets.contains(where: { $0.count > 0 }) else { return selectedRiskWindow() }
        return buckets.max { $0.count < $1.count }?.window ?? selectedRiskWindow()
    }

    private func inferredRiskWindow() -> RiskWindow {
        let events = data.urgeStarts
        guard !events.isEmpty else { return .evening }
        let counts = Dictionary(grouping: events, by: window(for:)).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? .evening
    }

    private func appendSlip(at date: Date, trigger: String, guardrail: String,
                            deduplicateSameDay: Bool = false) {
        let calendar = Calendar.current
        if deduplicateSameDay && data.slips.contains(where: { calendar.isDate($0, inSameDayAs: date) }) { return }
        if let latest = data.slips.max(), abs(date.timeIntervalSince(latest)) < 10 * 60 { return }
        data.slips.append(date)
        data.slipReflections.append(SlipReflection(date: date, trigger: trigger, guardrail: guardrail))
        if let index = data.dailyCheckIns.lastIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            data.dailyCheckIns[index].status = .used
        } else {
            // An urge/use log establishes today's status without pretending a
            // separate daily check-in happened.
            data.dailyCheckIns.append(DailyCheckIn(date: date, status: .used))
        }
        data.lastCelebratedDay = 0
        AppEvents.log("slip_logged", trigger)
    }

    private func window(for date: Date) -> RiskWindow {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<23: return .evening
        default: return .lateNight
        }
    }
}

#if DEBUG
/// Launch-argument hooks used only to capture screenshots without driving the UI.
/// Activated via env vars (SIMCTL_CHILD_DEMO_SEED / SIMCTL_CHILD_DEMO_SCREEN).
enum Demo {
    static let seed = ProcessInfo.processInfo.environment["DEMO_SEED"] != nil
    static let screen = ProcessInfo.processInfo.environment["DEMO_SCREEN"]

    static func seededData() -> QuitData {
        var d = QuitData.empty
        if screen == "onboarding" { return d }
        d.quitDate = Date().addingTimeInterval(-12 * 86_400)
        d.weeklySpend = 60
        d.sessionsPerDay = 4
        d.reasons = [Reason.clarity.rawValue, Reason.dreams.rawValue,
                     Reason.sleep.rawValue, Reason.money.rawValue]
        d.riskWindow = RiskWindow.evening.rawValue
        d.hasOnboarded = true
        d.hasSeenPaywall = true   // demo lands on Home, not the paywall (unless DEMO_SCREEN=paywall)
        d.urgeStarts = [Date().addingTimeInterval(-5 * 86_400),
                        Date().addingTimeInterval(-3 * 86_400),
                        Date().addingTimeInterval(-86_400)]
        d.urgesBeaten = [Date().addingTimeInterval(-3 * 86_400),
                         Date().addingTimeInterval(-86_400)]
        d.dailyCheckIns = [
            DailyCheckIn(date: Date().addingTimeInterval(-3 * 86_400), status: .clear, symptom: "Sleep"),
            DailyCheckIn(date: Date().addingTimeInterval(-2 * 86_400), status: .clear),
            DailyCheckIn(date: Date().addingTimeInterval(-86_400), status: .clear, symptom: "Mood")
        ]
        d.exitPlan = ExitPlan(cue: "After work", need: "Unwind", action: "Take a walk")
        d.lastCelebratedDay = 7
        return d
    }
}
#endif
