import Foundation

/// Labels for in-app troubleshooting when live Health data does not appear.
enum HomeDataSourceLabel: String, Sendable {
    case loading = "Loading…"
    case health = "Health"
    case healthEmpty = "Health (empty)"
    case demo = "Demo data"
    case error = "Error"
}

enum HealthAccessCopy {
    static let openHealthSettings = """
    Allow Health access for Wuhu:
    1. Open the Settings app
    2. Tap Health → Data Access & Devices → Wuhu
    3. Turn on the categories you want to share (Steps, Sleep, and so on)
    """

    static func hasAnyMetric(on day: DailyStats) -> Bool {
        day.steps != nil
            || day.sleep != nil
            || day.activeCalories != nil
            || day.restingCalories != nil
            || day.restingHeartRate != nil
            || day.hrvSDNN != nil
            || day.intakeCalories != nil
    }
}
