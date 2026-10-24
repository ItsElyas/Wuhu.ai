import Foundation

/// R2 six-tier Wuhu Scale Level ladder (1.0–6.0 composite).
enum WSLScaleRank: Int, Codable, Comparable, Sendable {
    case subPlayer = 1
    case lowTierPlayer = 2
    case midTierPlayer = 3
    case highTierPlayer = 4
    case goatLite = 5
    case trueGoat = 6

    static func < (lhs: WSLScaleRank, rhs: WSLScaleRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(compositeScore score: Double) -> WSLScaleRank {
        switch score {
        case ..<1.8: return .subPlayer
        case ..<2.7: return .lowTierPlayer
        case ..<3.7: return .midTierPlayer
        case ..<4.7: return .highTierPlayer
        case ..<5.6: return .goatLite
        default: return .trueGoat
        }
    }

    var title: String {
        switch self {
        case .subPlayer: return "Sub-Player"
        case .lowTierPlayer: return "Low Tier Player"
        case .midTierPlayer: return "Mid Tier Player"
        case .highTierPlayer: return "High Tier Player"
        case .goatLite: return "GOAT Lite"
        case .trueGoat: return "True GOAT"
        }
    }
}

struct SubMetric: Codable, Sendable, Equatable {
    let name: String
    let rawValue: Double
    let unit: String
    let score: Double
    let weight: Double
    let notes: String
}

struct WSLCompositeEvaluation: Codable, Sendable, Equatable {
    let sport: AthleteOnboardingEngine.SportDiscipline
    let gender: AthleteOnboardingEngine.Gender
    let compositeScore: Double
    let rank: WSLScaleRank
    let confidencePercentage: Int
    let isProvisional: Bool
    let subMetrics: [SubMetric]
    let feedbackComment: String
}

/// Home card presentation (R2 ladder, not legacy `WSLRank` abbreviations).
struct WSLScorePresentation: Equatable, Sendable {
    var headline: String
    var detail: String?

    static let collectingProfile = WSLScorePresentation(headline: "Collecting profile", detail: nil)
    static let midTierPlaceholder = WSLScorePresentation(headline: "Mid Tier Player", detail: "Add WSL metrics in Settings")

    static func from(evaluation: WSLCompositeEvaluation) -> WSLScorePresentation {
        let score = String(format: "%.2f / 6.0", evaluation.compositeScore)
        return WSLScorePresentation(
            headline: evaluation.rank.title,
            detail: evaluation.isProvisional ? "\(score) · estimated" : score
        )
    }
}
