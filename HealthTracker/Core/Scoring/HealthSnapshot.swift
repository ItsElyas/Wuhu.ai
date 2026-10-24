import Foundation

/// Compact Apple Health summary sent to the LLM. Schema version 1.
struct HealthSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var generatedAt: String
    var windowDays: Int
    var profile: SnapshotProfile
    var today: SnapshotToday
    var dailyHistory: [SnapshotDay]
    var bodyStatus: [SnapshotBodyStatus]
    var baselines: SnapshotBaselines
    var dataQuality: SnapshotDataQuality

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case generatedAt = "generated_at"
        case windowDays = "window_days"
        case profile
        case today
        case dailyHistory = "daily_history"
        case bodyStatus = "body_status"
        case baselines
        case dataQuality = "data_quality"
    }
}

struct SnapshotProfile: Codable, Equatable, Sendable {
    var ageYears: Int?
    var biologicalSex: String?
    var heightCm: Double?
    var weightKg: Double?

    enum CodingKeys: String, CodingKey {
        case ageYears = "age_years"
        case biologicalSex = "biological_sex"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
    }
}

struct SnapshotToday: Codable, Equatable, Sendable {
    var steps: Int?
    var activeKcal: Double?
    var basalKcal: Double?
    var restingHrBpm: Double?
    var latestHrBpm: Double?
    var hrvSdnnMs: Double?
    var sleep: SnapshotSleep?
    var workouts: [SnapshotWorkout]

    enum CodingKeys: String, CodingKey {
        case steps
        case activeKcal = "active_kcal"
        case basalKcal = "basal_kcal"
        case restingHrBpm = "resting_hr_bpm"
        case latestHrBpm = "latest_hr_bpm"
        case hrvSdnnMs = "hrv_sdnn_ms"
        case sleep
        case workouts
    }
}

struct SnapshotSleep: Codable, Equatable, Sendable {
    var totalHours: Double?
    var inBedHours: Double?
    var deepHours: Double?
    var remHours: Double?
    var coreHours: Double?
    var awakeHours: Double?
    var bedtime: String?
    var wakeTime: String?

    enum CodingKeys: String, CodingKey {
        case totalHours = "total_hours"
        case inBedHours = "in_bed_hours"
        case deepHours = "deep_hours"
        case remHours = "rem_hours"
        case coreHours = "core_hours"
        case awakeHours = "awake_hours"
        case bedtime
        case wakeTime = "wake_time"
    }
}

struct SnapshotWorkout: Codable, Equatable, Sendable {
    var type: String
    var minutes: Double
    var kcal: Double?
    var avgHrBpm: Double?
    var maxHrBpm: Double?

    enum CodingKeys: String, CodingKey {
        case type
        case minutes
        case kcal
        case avgHrBpm = "avg_hr_bpm"
        case maxHrBpm = "max_hr_bpm"
    }
}

struct SnapshotDay: Codable, Equatable, Sendable {
    var date: String
    var steps: Int?
    var activeKcal: Double?
    var restingHrBpm: Double?
    var hrvSdnnMs: Double?
    var sleepHours: Double?
    var workoutMinutes: Double?

    enum CodingKeys: String, CodingKey {
        case date
        case steps
        case activeKcal = "active_kcal"
        case restingHrBpm = "resting_hr_bpm"
        case hrvSdnnMs = "hrv_sdnn_ms"
        case sleepHours = "sleep_hours"
        case workoutMinutes = "workout_minutes"
    }
}

struct SnapshotBodyStatus: Codable, Equatable, Sendable {
    var part: String
    var status: String
    var severity: Int?
    var intensity: Double?
    var daysSinceStart: Int?
    var hoursSinceLastLoad: Double?

    enum CodingKeys: String, CodingKey {
        case part
        case status
        case severity
        case intensity
        case daysSinceStart = "days_since_start"
        case hoursSinceLastLoad = "hours_since_last_load"
    }
}

struct SnapshotBaselines: Codable, Equatable, Sendable {
    var restingHrBpm30dAvg: Double?
    var hrvSdnnMs30dAvg: Double?
    var sleepHours30dAvg: Double?
    var steps30dAvg: Double?
    var sleepConsistencyStddevMin: Double?

    enum CodingKeys: String, CodingKey {
        case restingHrBpm30dAvg = "resting_hr_bpm_30d_avg"
        case hrvSdnnMs30dAvg = "hrv_sdnn_ms_30d_avg"
        case sleepHours30dAvg = "sleep_hours_30d_avg"
        case steps30dAvg = "steps_30d_avg"
        case sleepConsistencyStddevMin = "sleep_consistency_stddev_min"
    }
}

struct SnapshotDataQuality: Codable, Equatable, Sendable {
    var daysWithData: Int
    var missingMetrics: [String]

    enum CodingKeys: String, CodingKey {
        case daysWithData = "days_with_data"
        case missingMetrics = "missing_metrics"
    }
}
