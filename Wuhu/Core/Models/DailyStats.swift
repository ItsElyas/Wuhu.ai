import Foundation

/// Aggregated health metrics for a single calendar day.
struct DailyStats: Equatable, Sendable, Identifiable {
    var id: Date { date }
    var date: Date
    var steps: Int?
    var activeCalories: Double?
    var restingCalories: Double?
    var restingHeartRate: Double?
    var latestHeartRate: Double?
    var hrvSDNN: Double?
    var sleep: SleepSummary?
    var workoutMinutes: Double?
    /// Dietary energy consumed, including what MyNetDiary writes to Apple Health.
    var intakeCalories: Double? = nil
    var proteinGrams: Double? = nil
    var carbGrams: Double? = nil
    var fatGrams: Double? = nil
    /// Walking plus running distance for the day, in miles.
    var distanceMiles: Double? = nil
}

struct SleepSummary: Equatable, Sendable {
    var totalHours: Double
    var inBedHours: Double?
    var deepHours: Double?
    var remHours: Double?
    var coreHours: Double?
    var awakeHours: Double?
    var bedtime: Date?
    var wakeTime: Date?
}
