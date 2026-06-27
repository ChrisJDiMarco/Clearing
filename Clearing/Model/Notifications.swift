import Foundation
import UserNotifications

/// Local notifications: a daily check-in nudge + one notification per upcoming
/// recovery milestone (scheduled from the clean-start date). 100% local, no server.
enum Reminders {
    private static let center = UNUserNotificationCenter.current()

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(cleanStart: Date, dailyHour: Int = 9) {
        center.removeAllPendingNotificationRequests()

        // Daily check-in reminder
        var daily = DateComponents()
        daily.hour = dailyHour
        daily.minute = 0
        let dailyContent = UNMutableNotificationContent()
        dailyContent.title = "Stay clear today"
        dailyContent.body = "One tap keeps your streak alive. You've got this."
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
            content.title = "\(milestone.badge) 🍃"
            content.body = milestone.fact
            content.sound = .default
            center.add(UNNotificationRequest(
                identifier: "clearing.milestone.\(milestone.day)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: fireDate.timeIntervalSince(now), repeats: false)))
        }
    }

    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
