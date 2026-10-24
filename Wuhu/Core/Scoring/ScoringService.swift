import Foundation

protocol ScoringService: Sendable {
    func score(snapshot: HealthSnapshot) async throws -> ScoreResult
}

enum ScoringError: LocalizedError {
    case invalidResponse
    case network(String)
    case missingAPIKey
    case contradictory(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The scoring response could not be read."
        case .network(let message): return message
        case .missingAPIKey: return "No API key configured."
        case .contradictory(let reason): return reason
        }
    }
}

struct MockScoringService: ScoringService {
    var fixtureName: String?

    func score(snapshot: HealthSnapshot) async throws -> ScoreResult {
        if snapshot.dataQuality.daysWithData < VitalityConfig.minimumDaysOfData {
            return ScoreResult(
                schemaVersion: 1,
                vitalityAge: nil,
                readiness: nil,
                effort: nil,
                sleepScore: nil,
                method: "Insufficient history.",
                insufficientData: true,
                disclaimer: "Estimate for motivation only, not medical advice."
            )
        }

        if let fixtureName,
           let url = Bundle.main.url(forResource: fixtureName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           var decoded = try? JSONDecoder().decode(ScoreResult.self, from: data) {
            decoded.clamp()
            return decoded
        }

        let calculator = VitalityAgeCalculator()
        let input = VitalityAgeCalculator.Input(
            chronologicalAge: snapshot.profile.ageYears ?? 30,
            daysWithData: snapshot.dataQuality.daysWithData,
            avgRestingHR: snapshot.baselines.restingHrBpm30dAvg,
            avgSleepHours: snapshot.baselines.sleepHours30dAvg,
            sleepConsistencyStddevMinutes: snapshot.baselines.sleepConsistencyStddevMin,
            avgSteps: snapshot.baselines.steps30dAvg,
            avgWorkoutMinutes: averageWorkoutMinutes(snapshot),
            avgHRV: snapshot.baselines.hrvSdnnMs30dAvg
        )
        return calculator.scoreResult(from: input)
    }

    private func averageWorkoutMinutes(_ snapshot: HealthSnapshot) -> Double? {
        let values = snapshot.dailyHistory.compactMap(\.workoutMinutes)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

struct LLMScoringService: ScoringService {
    var apiKey: String
    var baseURL: URL
    var model: String
    var session: URLSession = .shared

    func score(snapshot: HealthSnapshot) async throws -> ScoreResult {
        guard !apiKey.isEmpty, apiKey != "your_api_key_here" else {
            throw ScoringError.missingAPIKey
        }

        let encoder = JSONEncoder()
        let snapshotData = try encoder.encode(snapshot)
        let snapshotJSON = String(data: snapshotData, encoding: .utf8) ?? "{}"

        do {
            return try await requestScore(snapshotJSON: snapshotJSON)
        } catch {
            // Retry once on decode/network failure.
            return try await requestScore(snapshotJSON: snapshotJSON)
        }
    }

    private func requestScore(snapshotJSON: String) async throws -> ScoreResult {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": ScoringPrompt.system],
                ["role": "user", "content": snapshotJSON],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ScoringError.network("Scoring request failed.")
        }

        let content = try Self.extractMessageContent(from: data)
        guard let contentData = content.data(using: .utf8) else {
            throw ScoringError.invalidResponse
        }

        var result = try JSONDecoder().decode(ScoreResult.self, from: contentData)
        result.clamp()
        try Self.validate(result, against: snapshotJSON)
        return result
    }

    private static func extractMessageContent(from data: Data) throws -> String {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw ScoringError.invalidResponse
        }
        return content
    }

    private static func validate(_ result: ScoreResult, against snapshotJSON: String) throws {
        if result.insufficientData {
            return
        }
        // Reject "great" readiness when the snapshot clearly has no days of data.
        if snapshotJSON.contains("\"days_with_data\":0"),
           (result.readiness?.label?.lowercased() == "great" || (result.readiness?.score ?? 0) > 80) {
            throw ScoringError.contradictory("Readiness contradicts empty history.")
        }
    }
}

/// Forces `AppEnvironment.refreshScores` to use the on-device Vitality Age calculator.
private struct LocalFallbackScoringService: ScoringService {
    func score(snapshot: HealthSnapshot) async throws -> ScoreResult {
        throw ScoringError.missingAPIKey
    }
}

enum ScoringServiceFactory {
    static func make(aiEnabled: Bool) -> any ScoringService {
        guard aiEnabled else {
            return LocalFallbackScoringService()
        }
        let key = Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") as? String ?? ""
        let base = Bundle.main.object(forInfoDictionaryKey: "LLM_BASE_URL") as? String
            ?? "https://api.openai.com/v1"
        let model = Bundle.main.object(forInfoDictionaryKey: "LLM_MODEL") as? String ?? "gpt-4o-mini"
        let cleanedBase = base
            .replacingOccurrences(of: "\\/", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: cleanedBase), !key.isEmpty, key != "your_api_key_here" else {
            return LocalFallbackScoringService()
        }
        return LLMScoringService(apiKey: key, baseURL: url, model: model)
    }
}
