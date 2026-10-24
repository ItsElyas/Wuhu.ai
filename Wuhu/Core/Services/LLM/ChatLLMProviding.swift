import Foundation

/// One conversation turn sent to a chat LLM. Provider-neutral; each client maps roles to its own wire format.
struct ChatLLMMessage: Sendable, Equatable {
    enum Role: String, Sendable {
        case user
        case assistant
    }

    var role: Role
    var content: String
}

/// A function call the model asked the app to run (e.g. `update_wear_and_tear`).
struct ChatLLMToolCall: Sendable, Equatable {
    var id: String
    var name: String
    /// Arguments as a JSON object string, so callers decode with `JSONDecoder`.
    var argumentsJSON: String
}

/// Parsed model output: visible reply text plus any requested tool calls.
struct ChatLLMCompletion: Sendable, Equatable {
    var content: String
    var toolCalls: [ChatLLMToolCall]
}

/// Chat backend used by `ChatOrchestrator`. Swap providers by adding a new conforming client.
protocol ChatLLMProviding: Sendable {
    /// - Parameters:
    ///   - systemInstructions: Persona, rules, and compact health context. Joined by the client.
    ///   - messages: Conversation history, oldest first.
    ///   - tools: Functions the model may call.
    ///   - temperature: `nil` uses the provider's recommended default.
    func complete(
        systemInstructions: [String],
        messages: [ChatLLMMessage],
        tools: [ChatLLMTool],
        temperature: Double?
    ) async throws -> ChatLLMCompletion
}

/// Previews and offline UI tests.
struct MockChatLLMClient: ChatLLMProviding {
    var completion: ChatLLMCompletion

    init(completion: ChatLLMCompletion = ChatLLMCompletion(content: "Mock reply.", toolCalls: [])) {
        self.completion = completion
    }

    func complete(
        systemInstructions: [String],
        messages: [ChatLLMMessage],
        tools: [ChatLLMTool],
        temperature: Double?
    ) async throws -> ChatLLMCompletion {
        try await Task.sleep(nanoseconds: 200_000_000)
        return completion
    }
}
