import Foundation
import SwiftData

struct ChatTurnOutcome: Sendable {
    var replyText: String
    var appliedActions: [ChatWearTearAction]
    var skippedActions: [(ChatWearTearAction, String)]
}

/// Pipelines user messages: health context → LLM → wear updates → assistant reply.
@MainActor
@Observable
final class ChatOrchestrator {
    private(set) var phase: ChatOrchestratorPhase = .idle

    private let llmClient: (any ChatLLMProviding)?
    private static let historyLimit = 20

    init(llmClient: (any ChatLLMProviding)?) {
        self.llmClient = llmClient
    }

    /// Gemini when the user consented to AI and `GEMINI_API_KEY` is set; otherwise on-device fallback.
    static func make(settings: AppSettings) -> ChatOrchestrator {
        guard settings.aiScoringConsent,
              GeminiConfiguration.isConfigured,
              let url = GeminiConfiguration.baseURL else {
            return ChatOrchestrator(llmClient: nil)
        }
        return ChatOrchestrator(
            llmClient: GeminiChatClient(
                apiKey: GeminiConfiguration.apiKey,
                baseURL: url,
                model: GeminiConfiguration.model
            )
        )
    }

    var usesRemoteLLM: Bool { llmClient != nil }

    /// Short status for the chat header so it is obvious whether replies come from Gemini.
    var backendStatus: String {
        if usesRemoteLLM {
            return "AI: Gemini (\(GeminiConfiguration.model))"
        }
        if !GeminiConfiguration.isConfigured {
            return "Offline replies: add GEMINI_API_KEY to Secrets.xcconfig and rebuild."
        }
        return "Offline replies: turn on Settings → Send health summary to AI."
    }

    func prepareWellnessCheckIn(
        app: AppEnvironment,
        modelContext: ModelContext
    ) async throws -> String {
        phase = .readingHealth
        let context = ChatOrchestratorTools.readHealthContext(from: app)
        await Task.yield()

        phase = .thinking
        defer { phase = .idle }

        if let llmClient {
            let completion = try await llmClient.complete(
                systemInstructions: ChatSystemPrompt.instructions(
                    contextJSON: context.compactJSON(),
                    playerProfile: app.playerProfileStore.profile,
                    wslEvaluation: app.currentWSLEvaluation
                ),
                messages: [
                    ChatLLMMessage(
                        role: .user,
                        content: WellnessCheckInPrompt.orchestratorUserMessage(context: context)
                    ),
                ],
                tools: [],
                temperature: nil
            )
            GeminiChatDiagnostics.recordSuccess()
            return ChatOrchestratorJSON.parse(completion).message
        }
        return ChatLocalFallback.wellnessCheckIn(context: context).message
    }

    func handleTurn(
        userMessage: String,
        turns: [ChatTurn],
        app: AppEnvironment,
        modelContext: ModelContext
    ) async throws -> ChatTurnOutcome {
        defer { phase = .idle }

        phase = .readingHealth
        let context = ChatOrchestratorTools.readHealthContext(from: app)
        await Task.yield()

        phase = .thinking
        let parsed: ChatOrchestratorResult
        if let llmClient {
            let history = turns.suffix(Self.historyLimit).compactMap { turn -> ChatLLMMessage? in
                switch turn.role {
                case .user: return ChatLLMMessage(role: .user, content: turn.content)
                case .assistant: return ChatLLMMessage(role: .assistant, content: turn.content)
                case .system: return nil
                }
            }
            let completion = try await llmClient.complete(
                systemInstructions: ChatSystemPrompt.instructions(
                    contextJSON: context.compactJSON(),
                    playerProfile: app.playerProfileStore.profile,
                    wslEvaluation: app.currentWSLEvaluation
                ),
                messages: history,
                tools: [.updateWearAndTear],
                temperature: nil
            )
            GeminiChatDiagnostics.recordSuccess()
            parsed = ChatOrchestratorJSON.parse(completion)
        } else {
            parsed = try await ChatLocalFallback.reply(to: turns, context: context)
        }

        phase = .updating
        let outcome = ChatOrchestratorTools.applyWearUpdates(
            actions: parsed.actions,
            lastUserMessage: userMessage,
            modelContext: modelContext,
            app: app
        )
        await Task.yield()

        var replyText = parsed.message
        if replyText.isEmpty {
            // The model may return only a function call; summarize what changed instead.
            replyText = Self.summary(of: outcome.applied)
        }
        if !outcome.skipped.isEmpty {
            let reasons = outcome.skipped.map { "\($0.0.part): \($0.1)" }.joined(separator: "; ")
            replyText += "\n\nNote: Some body updates were skipped — \(reasons)."
        }

        return ChatTurnOutcome(
            replyText: replyText,
            appliedActions: outcome.applied,
            skippedActions: outcome.skipped
        )
    }

    private static func summary(of applied: [ChatWearTearAction]) -> String {
        let parts = applied.compactMap { ChatWearTearActionParser.displayName(for: $0) }
        guard !parts.isEmpty else {
            return "Sorry, I couldn't put together a reply. Could you rephrase that?"
        }
        return "I updated your Body Map: \(parts.joined(separator: ", ")). Pull to refresh on Home to see wear colors."
    }
}
