import Foundation

/// Why the user is quitting — drives onboarding personalization + copy.
enum Reason: String, Codable, CaseIterable, Identifiable {
    case clarity = "Mental clarity"
    case money = "Save money"
    case sleep = "Better sleep"
    case dreams = "Vivid dreams"
    case motivation = "Motivation"
    case control = "Take control"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .clarity: "brain.head.profile"
        case .money: "dollarsign.circle.fill"
        case .sleep: "moon.stars.fill"
        case .dreams: "sparkles"
        case .motivation: "bolt.fill"
        case .control: "checkmark.shield.fill"
        }
    }
}

/// When the user is most likely to want support. Stored as raw text so old data
/// still decodes cleanly if the enum changes later.
enum RiskWindow: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case lateNight = "Late night"
    case throughoutDay = "Throughout day"

    var id: String { rawValue }
    static let clockWindows: [RiskWindow] = [.morning, .afternoon, .evening, .lateNight]

    var label: String {
        switch self {
        case .morning: "Morning reset"
        case .afternoon: "Afternoon dip"
        case .evening: "Evening unwind"
        case .lateNight: "Late-night drift"
        case .throughoutDay: "It varies throughout the day"
        }
    }

    var shortLabel: String {
        switch self {
        case .morning: "morning"
        case .afternoon: "afternoon"
        case .evening: "evening"
        case .lateNight: "late night"
        case .throughoutDay: "any time"
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.haze.fill"
        case .lateNight: "moon.stars.fill"
        case .throughoutDay: "clock.arrow.circlepath"
        }
    }

    var startHour: Int {
        switch self {
        case .morning: 7
        case .afternoon: 14
        case .evening: 19
        case .lateNight: 23
        case .throughoutDay: 19 // Optional daily reminder, never treated as a risk window.
        }
    }

    static func from(_ raw: String?) -> RiskWindow? {
        raw.flatMap { RiskWindow(rawValue: $0) }
    }
}

struct SlipReflection: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var trigger: String
    var guardrail: String

    init(date: Date = Date(), trigger: String, guardrail: String) {
        self.date = date
        self.trigger = trigger
        self.guardrail = guardrail
    }
}

/// A daily check-in is an observation, not evidence of abstinence unless the
/// user explicitly says the day was clear.
enum UseStatus: String, Codable {
    case clear
    case used
}

enum UrgeOutcome: String, Codable {
    case okay
    case stillWant
    case used
}

struct DailyCheckIn: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var status: UseStatus
    var symptom: String?

    init(date: Date = Date(), status: UseStatus, symptom: String? = nil) {
        self.date = date
        self.status = status
        self.symptom = symptom
    }
}

struct UrgeRecord: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var need: String
    var action: String
    var outcome: UrgeOutcome

    init(date: Date = Date(), need: String, action: String, outcome: UrgeOutcome) {
        self.date = date
        self.need = need
        self.action = action
        self.outcome = outcome
    }
}

struct ExitPlan: Codable {
    var cue: String
    var need: String
    var action: String

    init(cue: String, need: String, action: String) {
        self.cue = cue
        self.need = need
        self.action = action
    }
}

struct DailyBrief {
    let icon: String
    let title: String
    let body: String
    let tint: String
}

struct WeeklyReport {
    let title: String
    let money: String
    let urges: Int
    let checkIns: Int
    let hardestWindow: RiskWindow
    let body: String
}

struct HeatmapBucket: Identifiable {
    let window: RiskWindow
    let count: Int
    let peak: Bool
    var id: String { window.rawValue }
}

struct RecoverySystem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let progress: Double
}

/// The single source of truth. Everything the app shows is derived from this.
/// 100% local — encoded to UserDefaults, no backend.
struct QuitData: Codable {
    var quitDate: Date
    var weeklySpend: Double
    var sessionsPerDay: Double
    var reasons: [String]
    var riskWindow: String?
    var slips: [Date] = []
    var slipReflections: [SlipReflection] = []
    var urgeStarts: [Date] = []
    var urgesBeaten: [Date] = []
    var checkIns: [Date] = []
    var dailyCheckIns: [DailyCheckIn] = []
    var urgeRecords: [UrgeRecord] = []
    var exitPlan: ExitPlan?
    var lastCelebratedDay: Double = 0
    var hasOnboarded: Bool = false
    var hasSeenPaywall: Bool = false
    var remindersEnabled: Bool = false

    init(quitDate: Date,
         weeklySpend: Double,
         sessionsPerDay: Double,
         reasons: [String],
         riskWindow: String? = nil,
         slips: [Date] = [],
         slipReflections: [SlipReflection] = [],
         urgeStarts: [Date] = [],
         urgesBeaten: [Date] = [],
         checkIns: [Date] = [],
         dailyCheckIns: [DailyCheckIn] = [],
         urgeRecords: [UrgeRecord] = [],
         exitPlan: ExitPlan? = nil,
         lastCelebratedDay: Double = 0,
         hasOnboarded: Bool = false,
         hasSeenPaywall: Bool = false,
         remindersEnabled: Bool = false) {
        self.quitDate = quitDate
        self.weeklySpend = weeklySpend
        self.sessionsPerDay = sessionsPerDay
        self.reasons = reasons
        self.riskWindow = riskWindow
        self.slips = slips
        self.slipReflections = slipReflections
        self.urgeStarts = urgeStarts
        self.urgesBeaten = urgesBeaten
        self.checkIns = checkIns
        self.dailyCheckIns = dailyCheckIns
        self.urgeRecords = urgeRecords
        self.exitPlan = exitPlan
        self.lastCelebratedDay = lastCelebratedDay
        self.hasOnboarded = hasOnboarded
        self.hasSeenPaywall = hasSeenPaywall
        self.remindersEnabled = remindersEnabled
    }

    static var empty: QuitData {
        QuitData(quitDate: Date(), weeklySpend: 45, sessionsPerDay: 3, reasons: [])
    }

    enum CodingKeys: String, CodingKey {
        case quitDate, weeklySpend, sessionsPerDay, reasons, riskWindow, slips
        case slipReflections, urgeStarts, urgesBeaten, checkIns, lastCelebratedDay
        case dailyCheckIns, urgeRecords, exitPlan
        case hasOnboarded, hasSeenPaywall, remindersEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quitDate = try c.decodeIfPresent(Date.self, forKey: .quitDate) ?? Date()
        weeklySpend = try c.decodeIfPresent(Double.self, forKey: .weeklySpend) ?? 45
        sessionsPerDay = try c.decodeIfPresent(Double.self, forKey: .sessionsPerDay) ?? 3
        reasons = try c.decodeIfPresent([String].self, forKey: .reasons) ?? []
        riskWindow = try c.decodeIfPresent(String.self, forKey: .riskWindow)
        slips = try c.decodeIfPresent([Date].self, forKey: .slips) ?? []
        slipReflections = try c.decodeIfPresent([SlipReflection].self, forKey: .slipReflections) ?? []
        urgeStarts = try c.decodeIfPresent([Date].self, forKey: .urgeStarts) ?? []
        urgesBeaten = try c.decodeIfPresent([Date].self, forKey: .urgesBeaten) ?? []
        checkIns = try c.decodeIfPresent([Date].self, forKey: .checkIns) ?? []
        dailyCheckIns = try c.decodeIfPresent([DailyCheckIn].self, forKey: .dailyCheckIns) ?? []
        urgeRecords = try c.decodeIfPresent([UrgeRecord].self, forKey: .urgeRecords) ?? []
        exitPlan = try c.decodeIfPresent(ExitPlan.self, forKey: .exitPlan)
        lastCelebratedDay = try c.decodeIfPresent(Double.self, forKey: .lastCelebratedDay) ?? 0
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? false
        hasSeenPaywall = try c.decodeIfPresent(Bool.self, forKey: .hasSeenPaywall) ?? false
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? false
    }
}

/// A recovery milestone. `day` is a threshold in days (0.5 == 12 hours).
struct Milestone: Identifiable, Equatable {
    let day: Double
    let title: String
    let badge: String
    let fact: String
    let icon: String

    var id: Double { day }

    static func == (lhs: Milestone, rhs: Milestone) -> Bool { lhs.day == rhs.day }
}

enum Milestones {
    /// Time markers for reflection, not a promised biological recovery timeline.
    static let all: [Milestone] = [
        Milestone(day: 0.5, title: "12 Hours", badge: "12 Hours Clear",
                  fact: "You made space for a different choice. What helped you get here?",
                  icon: "wind"),
        Milestone(day: 1, title: "1 Day", badge: "Day 1",
                  fact: "One day at a time is enough. Notice one thing you did for yourself.",
                  icon: "heart.fill"),
        Milestone(day: 3, title: "3 Days", badge: "3 Days Clear",
                  fact: "Early days can feel different for everyone. Keep the support that works close.",
                  icon: "flame.fill"),
        Milestone(day: 7, title: "1 Week", badge: "1 Week Clear",
                  fact: "A week of choices adds up. What has made this week easier?",
                  icon: "moon.stars.fill"),
        Milestone(day: 14, title: "2 Weeks", badge: "2 Weeks Clear",
                  fact: "You have learned something about your patterns. Keep the useful parts.",
                  icon: "sparkles"),
        Milestone(day: 30, title: "1 Month", badge: "1 Month Clear",
                  fact: "A month is a chance to look back with honesty and kindness.",
                  icon: "brain.head.profile"),
        Milestone(day: 60, title: "2 Months", badge: "2 Months Clear",
                  fact: "What have you made room for that matters to you?",
                  icon: "lungs.fill"),
        Milestone(day: 90, title: "90 Days", badge: "90 Days Clear",
                  fact: "Your path is your own. Keep what helps and ask for support when you need it.",
                  icon: "leaf.fill"),
    ]
}
