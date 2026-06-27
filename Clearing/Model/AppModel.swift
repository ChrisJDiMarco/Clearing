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
                               sessionsPerDay: data.sessionsPerDay))
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

    func moneySaved(asOf now: Date = Date()) -> Double {
        data.weeklySpend / (7 * 86_400) * secondsClean(asOf: now)
    }

    func sessionsAvoided(asOf now: Date = Date()) -> Double {
        data.sessionsPerDay * (secondsClean(asOf: now) / 86_400)
    }

    func hoursReclaimed(asOf now: Date = Date()) -> Double {
        sessionsAvoided(asOf: now) * 0.5
    }

    /// 0...1 — how warm the hero gradient should glow (full "dawn" at 30 days).
    func dawnProgress(asOf now: Date = Date()) -> Double {
        min(1, secondsClean(asOf: now) / (30 * 86_400))
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
    }

    // MARK: - Daily check-in

    var hasCheckedInToday: Bool {
        guard let last = data.checkIns.max() else { return false }
        return Calendar.current.isDateInToday(last)
    }

    func checkIn() {
        let today = Calendar.current.startOfDay(for: Date())
        if !data.checkIns.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            data.checkIns.append(today)
        }
    }

    func isCheckedIn(on day: Date) -> Bool {
        data.checkIns.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    // MARK: - Actions

    func logSlip() {
        data.slips.append(Date())
        data.lastCelebratedDay = 0
    }

    func beatUrge() {
        data.urgesBeaten.append(Date())
    }

    var urgesBeaten: Int { data.urgesBeaten.count }

    func completeOnboarding(quitDate: Date, weeklySpend: Double,
                            sessionsPerDay: Double, reasons: [Reason]) {
        data.quitDate = quitDate
        data.weeklySpend = weeklySpend
        data.sessionsPerDay = sessionsPerDay
        data.reasons = reasons.map(\.rawValue)
        data.remindersEnabled = true
        data.hasOnboarded = true
    }

    /// Schedule or clear local reminders to match the current state.
    func refreshReminders() {
        if data.remindersEnabled {
            Reminders.schedule(cleanStart: cleanStart)
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
}

#if DEBUG
/// Launch-argument hooks used only to capture screenshots without driving the UI.
/// Activated via env vars (SIMCTL_CHILD_DEMO_SEED / SIMCTL_CHILD_DEMO_SCREEN).
enum Demo {
    static let seed = ProcessInfo.processInfo.environment["DEMO_SEED"] != nil
    static let screen = ProcessInfo.processInfo.environment["DEMO_SCREEN"]

    static func seededData() -> QuitData {
        var d = QuitData.empty
        d.quitDate = Date().addingTimeInterval(-12 * 86_400)
        d.weeklySpend = 60
        d.sessionsPerDay = 4
        d.reasons = [Reason.clarity.rawValue, Reason.dreams.rawValue,
                     Reason.sleep.rawValue, Reason.money.rawValue]
        d.hasOnboarded = true
        d.hasSeenPaywall = true   // demo lands on Home, not the paywall (unless DEMO_SCREEN=paywall)
        d.urgesBeaten = [Date().addingTimeInterval(-3 * 86_400),
                         Date().addingTimeInterval(-86_400)]
        d.lastCelebratedDay = 7
        return d
    }
}
#endif
