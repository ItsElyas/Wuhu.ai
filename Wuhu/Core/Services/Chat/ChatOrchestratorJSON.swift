import Foundation

/// Parses orchestrator replies. Plain text plus tool calls is the primary path; a JSON envelope
/// `{ "message", "actions"? }` in the text is still accepted in case a prompt asks for it.
enum ChatOrchestratorJSON {
    private struct Envelope: Decodable {
        var message: String
        var actions: [ChatWearTearAction]?
    }

    static func parse(_ completion: ChatLLMCompletion) -> ChatOrchestratorResult {
        var result = parse(completion.content)
        for tool in completion.toolCalls {
            for action in ChatOrchestratorTools.actions(from: tool) where !result.actions.contains(action) {
                result.actions.append(action)
            }
        }
        return result
    }

    static func parse(_ raw: String) -> ChatOrchestratorResult {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let envelope = try? JSONDecoder().decode(Envelope.self, from: data) {
            return ChatOrchestratorResult(message: envelope.message, actions: envelope.actions ?? [])
        }
        if let block = extractJSONBlock(from: trimmed),
           let data = block.data(using: .utf8),
           let envelope = try? JSONDecoder().decode(Envelope.self, from: data) {
            return ChatOrchestratorResult(message: envelope.message, actions: envelope.actions ?? [])
        }
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}"),
           start < end {
            let slice = String(trimmed[start...end])
            if let data = slice.data(using: .utf8),
               let envelope = try? JSONDecoder().decode(Envelope.self, from: data) {
                return ChatOrchestratorResult(message: envelope.message, actions: envelope.actions ?? [])
            }
        }
        return ChatOrchestratorResult(message: trimmed, actions: [])
    }

    private static func extractJSONBlock(from text: String) -> String? {
        guard let range = text.range(of: "```json") else { return nil }
        let after = text[range.upperBound...]
        guard let end = after.range(of: "```") else { return nil }
        return String(after[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
