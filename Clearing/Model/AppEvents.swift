import OSLog

enum AppEvents {
    private static let logger = Logger(subsystem: "com.jarvis.clearing", category: "events")

    static func log(_ name: String, _ detail: String = "") {
        logger.info("\(name, privacy: .public) \(detail, privacy: .private)")
    }
}
