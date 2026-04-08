import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "zd.sprout"

    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let startup = Logger(subsystem: subsystem, category: "Startup")
}
