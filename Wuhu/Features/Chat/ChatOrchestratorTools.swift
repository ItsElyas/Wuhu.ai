import Foundation
import SwiftData

/// LLM-facing tool wrappers: read compact health, validate wear actions.
enum ChatOrchestratorTools {
    @MainActor
    static func readHealthContext(from app: AppEnvironment) -> ChatSessionContext {
        ChatSessionContext.make(from: app)
    }

    /// Drops unknown parts and clamps severity before apply.
    static func sanitizeActions(_ actions: [ChatWearTearAction]) -> [ChatWearTearAction] {
        actions.compactMap { action -> ChatWearTearAction? in
            guard BodyPartRegistry.resolvePart(action.part) != nil else { return nil }
            var copy = action
            if let severity = copy.severity {
                copy.severity = min(5, max(1, severity))
            }
            return copy
        }
    }

    @MainActor
    static func applyWearUpdates(
        actions: [ChatWearTearAction],
        lastUserMessage: String,
        modelContext: ModelContext,
        app: AppEnvironment
    ) -> ChatWearTearExecutor.Outcome {
        ChatWearTearExecutor.apply(
            actions: sanitizeActions(actions),
            lastUserMessage: lastUserMessage,
            modelContext: modelContext,
            app: app
        )
    }

    /// `update_wear_and_tear` tool-call arguments → wear actions. Other tools are ignored.
    static func actions(from toolCall: ChatLLMToolCall) -> [ChatWearTearAction] {
        guard toolCall.name == ChatLLMTool.updateWearAndTearName,
              let data = toolCall.argumentsJSON.data(using: .utf8) else { return [] }
        struct Args: Decodable { var actions: [ChatWearTearAction] }
        return (try? JSONDecoder().decode(Args.self, from: data))?.actions ?? []
    }
}
