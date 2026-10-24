import Foundation

/// Compact chat context — no raw HealthKit samples.
struct ChatSessionContext: Sendable {
    var snapshot: HealthSnapshot?
    var scores: ScoreResult?
    var readinessScore: Int?
    var wearSummaryLines: [String]
    var soreOrInjuredParts: [String]
    var wsl: WSLCompositeEvaluation? = nil
    var wslEstimatedFields: [String] = []

    @MainActor
    static func make(from app: AppEnvironment) -> ChatSessionContext {
        let wear = app.wearTearResult
        let wearLines = wear?.wear
            .filter { $0.value != .none }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue)=\($0.value.title)" } ?? []

        let bodyParts = app.lastSnapshot?.bodyStatus.map { "\($0.part)=\($0.status)" } ?? []

        let readiness: Int? = {
            if let score = app.latestScores?.readiness?.score {
                return Int(min(100, max(0, score)).rounded())
            }
            if let wear {
                return ReadinessEstimator.score(
                    wearResult: wear,
                    sleepHours: app.today?.sleep?.totalHours,
                    scoreResult: app.latestScores
                )
            }
            return nil
        }()

        return ChatSessionContext(
            snapshot: app.lastSnapshot,
            scores: app.latestScores,
            readinessScore: readiness,
            wearSummaryLines: wearLines,
            soreOrInjuredParts: bodyParts,
            wsl: app.currentWSLEvaluation,
            wslEstimatedFields: app.playerProfileStore.profile?.wslEvaluation == nil ? (app.autoWSL?.estimatedFields ?? []) : []
        )
    }

    func compactJSON() -> String {
        struct Payload: Encodable {
            var readiness: Int?
            var vitalityAgeYears: Double?
            var sleepScore: Int?
            var effort: Double?
            var wear: [String]
            var bodyStatus: [String]
            var todaySteps: Int?
            var sleepHoursLastNight: Double?
            var wslTier: String?
            var wslScore: Double?
            var wslConfidencePercent: Int?
            var wslEstimatedFields: [String]?
        }
        let payload = Payload(
            readiness: readinessScore,
            vitalityAgeYears: scores?.vitalityAge?.years,
            sleepScore: scores?.sleepScore?.score.map { Int(min(100, max(0, $0)).rounded()) },
            effort: scores?.effort?.score,
            wear: wearSummaryLines,
            bodyStatus: soreOrInjuredParts,
            todaySteps: snapshot?.today.steps,
            sleepHoursLastNight: snapshot?.today.sleep?.totalHours,
            wslTier: wsl?.rank.title,
            wslScore: wsl.map { ($0.compositeScore * 100).rounded() / 100 },
            wslConfidencePercent: wsl?.confidencePercentage,
            wslEstimatedFields: wslEstimatedFields.isEmpty ? nil : wslEstimatedFields
        )
        let data = (try? JSONEncoder().encode(payload)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
