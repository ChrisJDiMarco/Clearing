import Foundation

/// Compact snapshot shared from the app to the widget via an App Group.
/// (Duplicated lightweight in both targets — they're separate modules.)
enum WidgetShared {
    static let appGroup = "group.com.jarvis.clearing"
    static let key = "clearing.widget.snapshot"

    struct Snapshot: Codable {
        var cleanStart: Date
        var weeklySpend: Double
        var sessionsPerDay: Double
    }

    static func read() -> Snapshot? {
        let defaults = UserDefaults(suiteName: appGroup) ?? .standard
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return nil }
        return snap
    }

    /// Shown in previews / gallery / before the App Group is wired up.
    static var sample: Snapshot {
        Snapshot(cleanStart: Date().addingTimeInterval(-12 * 86_400), weeklySpend: 60, sessionsPerDay: 4)
    }
}
