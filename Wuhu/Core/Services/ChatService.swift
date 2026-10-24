import Foundation

protocol ChatService: Sendable {
    func reply(to messages: [ChatTurn], snapshot: HealthSnapshot?, scores: ScoreResult?) async throws -> String
}

struct ChatTurn: Sendable {
    var role: ChatRole
    var content: String
}

struct MockChatService: ChatService {
    func reply(to messages: [ChatTurn], snapshot: HealthSnapshot?, scores: ScoreResult?) async throws -> String {
        try await Task.sleep(nanoseconds: 400_000_000)
        let last = messages.last(where: { $0.role == .user })?.content.lowercased() ?? ""

        if let injured = snapshot?.bodyStatus.first(where: { $0.status == "injured" }) {
            if last.contains("injur") || last.contains("hurt") || last.contains("pain") || last.contains("heal") {
                return """
                You marked \(injured.part) as injured. I will not suggest training through that area. \
                Ease load, keep gentle daily movement if comfortable, and see a clinician or physical therapist \
                if it stays sore for a week, worsens, or limits walking. This is wellness guidance, not a diagnosis.
                """
            }
        }

        if last.contains("vitality") || last.contains("age") {
            if let years = scores?.vitalityAge?.years, let delta = scores?.vitalityAge?.deltaVsChronological {
                let younger = delta < 0
                return """
                Your Vitality Age is about \(String(format: "%.1f", years)) — \
                \(String(format: "%.1f", abs(delta))) years \(younger ? "younger" : "older") than your chronological age. \
                This is a motivation estimate from your recent averages, not a medical measurement.
                """
            }
            return "I do not have enough recent days of data yet to quote a Vitality Age. Keep syncing health data for at least 7 days."
        }

        if last.contains("sleep") {
            if let score = scores?.sleepScore?.score {
                return "Your Sleep Score is about \(Int(score)). \(scores?.sleepScore?.summary ?? "") Steady bedtimes help consistency."
            }
            return "I do not see a sleep score yet. Check that sleep is recorded in Apple Health or enable Mock Data."
        }

        if last.contains("ready") || last.contains("recover") {
            if let score = scores?.readiness?.score {
                return "Readiness is about \(Int(score)) (\(scores?.readiness?.label ?? "n/a")). \(scores?.readiness?.summary ?? "")"
            }
        }

        let steps = snapshot?.today.steps.map(String.init) ?? "unknown"
        return """
        Based on today's snapshot, steps are \(steps). Ask me about Vitality Age, readiness, sleep, effort, \
        or a body area you marked injured. I share general wellness info only — not medical advice.
        """
    }
}

struct LLMChatService: ChatService {
    var apiKey: String
    var baseURL: URL
    var model: String
    var session: URLSession = .shared

    func reply(to messages: [ChatTurn], snapshot: HealthSnapshot?, scores: ScoreResult?) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var payloadMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt(snapshot: snapshot, scores: scores)],
        ]
        for turn in messages.suffix(20) {
            payloadMessages.append([
                "role": turn.role == .assistant ? "assistant" : "user",
                "content": turn.content,
            ])
        }

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.4,
            "messages": payloadMessages,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ScoringError.network("Chat request failed.")
        }
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

    private func systemPrompt(snapshot: HealthSnapshot?, scores: ScoreResult?) -> String {
        let encoder = JSONEncoder()
        let snap = (try? encoder.encode(snapshot)).flatMap { String(data: $0, encoding: .utf8) } ?? "null"
        let score = (try? encoder.encode(scores)).flatMap { String(data: $0, encoding: .utf8) } ?? "null"
        return """
        You are HealthTracker's wellness chatbot. General wellness information only — never diagnose or prescribe.
        Suggest seeing a clinician for concerning symptoms. Do not invent numbers not present in the context.
        Never tell the user to train through a body part marked injured (status injured / red).
        Context HealthSnapshot JSON: \(snap)
        Context ScoreResult JSON: \(score)
        """
    }
}
