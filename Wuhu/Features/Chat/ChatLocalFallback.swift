import Foundation

/// Keyword chat when the Gemini key is missing or AI consent is off.
enum ChatLocalFallback {
    static func reply(to messages: [ChatTurn], context: ChatSessionContext) async throws -> ChatOrchestratorResult {
        let mock = MockChatService()
        let text = try await mock.reply(to: messages, snapshot: context.snapshot, scores: context.scores)
        let lastUser = messages.last(where: { $0.role == .user })?.content ?? ""
        let actions = ChatWearTearActionParser.actions(from: lastUser)
        var message = text
        if !actions.isEmpty {
            let parts = actions.compactMap { ChatWearTearActionParser.displayName(for: $0) }.joined(separator: ", ")
            message += "\n\nI updated your Body Map for: \(parts). Pull to refresh on Home to see wear colors."
        }
        return ChatOrchestratorResult(message: message, actions: actions)
    }

    static func wellnessCheckIn(context: ChatSessionContext) -> ChatOrchestratorResult {
        ChatOrchestratorResult(message: WellnessCheckInPrompt.localOpener(context: context), actions: [])
    }
}
