import Foundation
import UserNotifications

/// Local notifications. Lock-screen copy stays neutral because quitting can be
/// private even when the user opts in to reminders.
enum Reminders {
    private static let center = UNUserNotificationCenter.current()
    private static var requestIDs: [String] {
        ["clearing.daily", "clearing.urge.followup"] + Milestones.all.map { "clearing.milestone.\($0.day)" }
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(cleanStart: Date, dailyHour: Int = 9) {
        center.removePendingNotificationRequests(withIdentifiers: requestIDs)

        // Daily check-in reminder
        var daily = DateComponents()
        daily.hour = dailyHour
        daily.minute = 0
        let dailyContent = UNMutableNotificationContent()
        dailyContent.title = "A moment for yourself"
        dailyContent.body = "Open Clearing when you're ready."
        dailyContent.sound = .default
        center.add(UNNotificationRequest(
            identifier: "clearing.daily",
            content: dailyContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: daily, repeats: true)))

        // One reminder per upcoming milestone
        let now = Date()
        for milestone in Milestones.all {
            let fireDate = cleanStart.addingTimeInterval(milestone.day * 86_400)
            guard fireDate > now.addingTimeInterval(60) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "A moment worth noticing"
            content.body = "Take a moment to reflect on your progress."
            content.sound = .default
            center.add(UNNotificationRequest(
                identifier: "clearing.milestone.\(milestone.day)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: fireDate.timeIntervalSince(now), repeats: false)))
        }
    }

    static func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: requestIDs)
    }

    static func scheduleUrgeFollowUp(action: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["clearing.urge.followup"])

        let content = UNMutableNotificationContent()
        content.title = "A gentle check-in"
        content.body = "How are you doing now?"
        content.sound = .default
        center.add(UNNotificationRequest(
            identifier: "clearing.urge.followup",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)))
    }
}
