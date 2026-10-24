import Foundation
import SwiftData

@MainActor
@Observable
final class ChatViewModel {
    var input = ""
    var errorMessage: String?
    private var didPrepareSession = false

    func prepareSessionIfNeeded(
        orchestrator: ChatOrchestrator,
        app: AppEnvironment,
        modelContext: ModelContext
    ) async {
        guard !didPrepareSession else { return }
        didPrepareSession = true
        guard app.settings.aiScoringConsent else { return }
        guard app.settings.chatWellnessCheckInEnabled else { return }

        let history = (try? modelContext.fetch(
            FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.createdAt)])
        )) ?? []
        guard history.isEmpty else { return }

        do {
            let message = try await orchestrator.prepareWellnessCheckIn(app: app, modelContext: modelContext)
            modelContext.insert(ChatMessage(role: .assistant, content: message))
            try? modelContext.save()
        } catch {
            if orchestrator.usesRemoteLLM {
                let detail = Self.userFacingError(error)
                errorMessage = detail
                GeminiChatDiagnostics.recordFailure(detail)
            }
            let context = ChatOrchestratorTools.readHealthContext(from: app)
            modelContext.insert(
                ChatMessage(
                    role: .assistant,
                    content: WellnessCheckInPrompt.localOpener(context: context)
                )
            )
            try? modelContext.save()
        }
    }

    func send(
        orchestrator: ChatOrchestrator,
        app: AppEnvironment,
        modelContext: ModelContext
    ) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input = ""
        errorMessage = nil

        let userMessage = ChatMessage(role: .user, content: trimmed)
        modelContext.insert(userMessage)
        try? modelContext.save()

        let history = (try? modelContext.fetch(
            FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.createdAt)])
        )) ?? []
        let turns = history.map { ChatTurn(role: $0.role, content: $0.content) }

        do {
            let outcome = try await orchestrator.handleTurn(
                userMessage: trimmed,
                turns: turns,
                app: app,
                modelContext: modelContext
            )
            modelContext.insert(ChatMessage(role: .assistant, content: outcome.replyText))
            try? modelContext.save()
        } catch {
            let detail = Self.userFacingError(error)
            errorMessage = detail
            if orchestrator.usesRemoteLLM {
                GeminiChatDiagnostics.recordFailure(detail)
            }
            modelContext.insert(
                ChatMessage(
                    role: .assistant,
                    content: Self.assistantFailureMessage(usesRemoteLLM: orchestrator.usesRemoteLLM, detail: detail)
                )
            )
            try? modelContext.save()
        }
    }

    private static func userFacingError(_ error: Error) -> String {
        if let llm = error as? ChatLLMError {
            return llm.errorDescription ?? "Gemini request failed."
        }
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private static func assistantFailureMessage(usesRemoteLLM: Bool, detail: String) -> String {
        if usesRemoteLLM {
            return "I couldn't get a reply from Gemini.\n\n\(detail)"
        }
        return "AI chat is off. Turn on Settings → Send health summary to AI, set GEMINI_API_KEY in Secrets.xcconfig, and rebuild."
    }
}
