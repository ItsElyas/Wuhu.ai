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

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case vitalityAge = "vitality_age"
        case readiness
        case effort
        case sleepScore = "sleep_score"
        case method
        case insufficientData = "insufficient_data"
        case disclaimer
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
