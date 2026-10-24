import ActivityKit
import Foundation

/// Live Activity for an in-progress Workout Hub session (Lock Screen + Dynamic Island).
/// Compiled into both the app and the WuhuWidgets extension (`Shared/` folder).
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Timer counts up from here, so it keeps running while the app is closed.
        var startedAt: Date
        /// "4 sets · 2,450 lbs" or "2.10 mi · 8:12 /mi".
        var detail: String
    }

    var sessionID: UUID
    var title: String
    /// SF Symbol for the workout kind.
    var symbol: String
}

enum WorkoutDeepLink {
    static let scheme = "wuhu"
    static let host = "workout"

    static func url(for sessionID: UUID) -> URL {
        URL(string: "\(scheme)://\(host)/\(sessionID.uuidString)") ?? URL(string: "\(scheme)://\(host)")!
    }

    static func isWorkoutURL(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == host
    }
}
