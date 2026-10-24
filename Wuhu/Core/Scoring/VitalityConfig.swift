import Foundation

/// Tunable weights and age-adjusted reference ranges for the local Vitality Age fallback.
enum VitalityConfig {
    /// Minimum days of data before showing a numeric Vitality Age.
    static let minimumDaysOfData = 7

    /// Maximum absolute age offset in years.
    static let maxAgeOffset = 10.0

    static let weights = MetricWeights(
        restingHeartRate: 0.25,
        sleepDuration: 0.20,
        sleepConsistency: 0.15,
        steps: 0.15,
        activeLoad: 0.15,
        hrv: 0.10
    )

    struct MetricWeights: Sendable {
        var restingHeartRate: Double
        var sleepDuration: Double
        var sleepConsistency: Double
        var steps: Double
        var activeLoad: Double
        var hrv: Double
    }

    /// Age-adjusted “good” targets used when population norms are needed.
    static func restingHRTarget(age: Int) -> Double {
        // Slightly higher acceptable resting HR with age.
        55 + Double(max(0, age - 20)) * 0.15
    }

    static let sleepHoursTarget = 7.5
    static let stepsTarget = 8_000.0
    static let activeMinutesTarget = 30.0
    static let hrvTargetMs = 55.0
}
