import Foundation

/// Seven-day rollup with averages and week-over-week change.
struct WeeklyStats: Equatable, Sendable {
    var days: [DailyStats]
    var averageSteps: Double?
    var averageActiveCalories: Double?
    var averageRestingHeartRate: Double?
    var averageSleepHours: Double?
    var averageWorkoutMinutes: Double?
    var stepsChangePercent: Double?
    var activeCaloriesChangePercent: Double?
    var restingHeartRateChangePercent: Double?
    var sleepChangePercent: Double?

    static func weekOverWeekChange(current: Double?, previous: Double?) -> Double? {
        guard let current, let previous, previous != 0 else { return nil }
        return ((current - previous) / previous) * 100
    }

    static func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
