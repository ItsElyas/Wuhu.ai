import Foundation

struct ScoreResult: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var vitalityAge: VitalityAgeScore?
    var readiness: LabeledScore?
    var effort: EffortScore?
    var sleepScore: LabeledScore?
    var method: String?
    var insufficientData: Bool
    var disclaimer: String?
    var egoScore: EgoScoreValue? = nil
    var dailyRecommendation: DailyRecommendationValue? = nil

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case vitalityAge = "vitality_age"
        case readiness
        case effort
        case sleepScore = "sleep_score"
        case method
        case insufficientData = "insufficient_data"
        case disclaimer
        case egoScore = "ego_score"
        case dailyRecommendation = "daily_recommendation"
    }

    /// Clamp scores to safe ranges after decode.
    mutating func clamp() {
        if var v = vitalityAge {
            v.deltaVsChronological = min(10, max(-10, v.deltaVsChronological ?? 0))
            vitalityAge = v
        }
        if var r = readiness {
            r.score = min(100, max(0, r.score ?? 0))
            readiness = r
        }
        if var s = sleepScore {
            s.score = min(100, max(0, s.score ?? 0))
            sleepScore = s
        }
        if var e = effort {
            let maxScale = e.scaleMax ?? 21
            e.score = min(maxScale, max(0, e.score ?? 0))
            e.scaleMax = maxScale
            effort = e
        }
        if var ego = egoScore, let score = ego.score {
            ego.score = min(100, max(0, score))
            egoScore = ego
        }
        if let recommendation = dailyRecommendation, recommendation.validated() == nil {
            dailyRecommendation = nil
        }
    }

    /// A recommendation whose split and targets are inside the allowed ranges.
    func validatedDailyPlan() -> (Split, DailyRecommendation)? {
        dailyRecommendation?.validated()
    }
}

struct VitalityAgeScore: Codable, Equatable, Sendable {
    var years: Double?
    var deltaVsChronological: Double?
    var confidence: String?
    var drivers: [ScoreDriver]?

    enum CodingKeys: String, CodingKey {
        case years
        case deltaVsChronological = "delta_vs_chronological"
        case confidence
        case drivers
    }
}

struct ScoreDriver: Codable, Equatable, Sendable, Identifiable {
    var id: String { metric + (note ?? "") }
    var metric: String
    var effectYears: Double?
    var note: String?

    enum CodingKeys: String, CodingKey {
        case metric
        case effectYears = "effect_years"
        case note
    }
}

struct LabeledScore: Codable, Equatable, Sendable {
    var score: Double?
    var label: String?
    var summary: String?
}

struct EffortScore: Codable, Equatable, Sendable {
    var score: Double?
    var scaleMax: Double?
    var summary: String?

    enum CodingKeys: String, CodingKey {
        case score
        case scaleMax = "scale_max"
        case summary
    }
}

struct EgoScoreValue: Codable, Equatable, Sendable {
    var score: Double?
    var summary: String?
}

struct DailyRecommendationValue: Codable, Equatable, Sendable {
    var split: String?
    var focus: String?
    var sleepHours: Double?
    var workoutMinutes: Int?
    var calories: Int?

    enum CodingKeys: String, CodingKey {
        case split
        case focus
        case sleepHours = "sleep_hours"
        case workoutMinutes = "workout_minutes"
        case calories
    }

    func validated() -> (Split, DailyRecommendation)? {
        guard let splitRaw = split, let split = Split(rawValue: splitRaw) else { return nil }
        guard let focus, !focus.isEmpty else { return nil }
        guard let sleepHours, (5...11).contains(sleepHours) else { return nil }
        guard let workoutMinutes, (0...180).contains(workoutMinutes) else { return nil }
        guard let calories, (1200...5000).contains(calories) else { return nil }
        return (
            split,
            DailyRecommendation(
                focus: focus,
                sleepHours: sleepHours,
                workoutMinutes: workoutMinutes,
                calories: calories
            )
        )
    }
}
