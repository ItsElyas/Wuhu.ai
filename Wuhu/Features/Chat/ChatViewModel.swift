import Foundation
import SwiftData

@MainActor
@Observable
final class ChatViewModel {
    var input = ""
    var isTyping = false
    var errorMessage: String?

    func send(
        using chatService: any ChatService,
        snapshot: HealthSnapshot?,
        scores: ScoreResult?,
        modelContext: ModelContext
    ) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input = ""
        errorMessage = nil

        let userMessage = ChatMessage(role: .user, content: trimmed)
        modelContext.insert(userMessage)
        try? modelContext.save()

        isTyping = true
        defer { isTyping = false }

        let history = (try? modelContext.fetch(
            FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.createdAt)])
        )) ?? []
        let turns = history.map { ChatTurn(role: $0.role, content: $0.content) }

        do {
            let reply = try await chatService.reply(to: turns, snapshot: snapshot, scores: scores)
            modelContext.insert(ChatMessage(role: .assistant, content: reply))
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            modelContext.insert(
                ChatMessage(
                    role: .assistant,
                    content: "I could not reach the chat service. Check your connection or use Mock Data."
                )
            )
            try? modelContext.save()
        }
    }
}
