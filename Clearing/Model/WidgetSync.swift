import Foundation
import WidgetKit

/// Writes a compact snapshot to the App Group so the widget can render the streak.
/// (Requires the "group.com.jarvis.clearing" App Group capability on both targets to
/// actually share across processes — falls back to the standard suite otherwise.)
enum WidgetSync {
    static let appGroup = "group.com.jarvis.clearing"
    static let key = "clearing.widget.snapshot"

    struct Snapshot: Codable {
        var cleanStart: Date
        var weeklySpend: Double
        var sessionsPerDay: Double
    }

    static func write(_ snap: Snapshot) {
        let defaults = UserDefaults(suiteName: appGroup) ?? .standard
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
