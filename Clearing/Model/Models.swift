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

/// The single source of truth. Everything the app shows is derived from this.
/// 100% local — encoded to UserDefaults, no backend.
struct QuitData: Codable {
    var quitDate: Date
    var weeklySpend: Double
    var sessionsPerDay: Double
    var reasons: [String]
    var slips: [Date] = []
    var urgesBeaten: [Date] = []
    var checkIns: [Date] = []
    var lastCelebratedDay: Double = 0
    var hasOnboarded: Bool = false
    var hasSeenPaywall: Bool = false
    var remindersEnabled: Bool = false

    static var empty: QuitData {
        QuitData(quitDate: Date(), weeklySpend: 45, sessionsPerDay: 3, reasons: [])
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
    /// Cannabis-specific recovery timeline. Framed as general information,
    /// not medical advice (see SettingsView disclaimer).
    static let all: [Milestone] = [
        Milestone(day: 0.5, title: "12 Hours", badge: "12 Hours Clear",
                  fact: "THC is already leaving your system and the mental fog is starting to lift.",
                  icon: "wind"),
        Milestone(day: 1, title: "1 Day", badge: "Day 1",
                  fact: "Your heart rate and blood pressure are settling back toward baseline.",
                  icon: "heart.fill"),
        Milestone(day: 3, title: "3 Days", badge: "3 Days Clear",
                  fact: "The toughest stretch usually peaks around now — and then it starts to ease.",
                  icon: "flame.fill"),
        Milestone(day: 7, title: "1 Week", badge: "1 Week Clear",
                  fact: "REM sleep is rebounding. Your dreams are coming back — often surprisingly vivid.",
                  icon: "moon.stars.fill"),
        Milestone(day: 14, title: "2 Weeks", badge: "2 Weeks Clear",
                  fact: "Focus and mental clarity sharpen as the brain fog keeps lifting.",
                  icon: "sparkles"),
        Milestone(day: 30, title: "1 Month", badge: "1 Month Clear",
                  fact: "Sleep quality and short-term memory are measurably improving.",
                  icon: "brain.head.profile"),
        Milestone(day: 60, title: "2 Months", badge: "2 Months Clear",
                  fact: "Energy and lung capacity are climbing back toward where they belong.",
                  icon: "lungs.fill"),
        Milestone(day: 90, title: "90 Days", badge: "90 Days Clear",
                  fact: "Your cannabinoid receptors have largely reset — your tolerance is back to baseline.",
                  icon: "leaf.fill"),
    ]
}
