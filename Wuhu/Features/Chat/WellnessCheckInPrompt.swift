import Foundation

/// Proactive “how are you doing?” templates for session start.
enum WellnessCheckInPrompt {
    static func orchestratorUserMessage(context: ChatSessionContext) -> String {
        """
        [session_start] Ask how the user feels today in one or two sentences. \
        Reference readiness or wear from context when useful. \
        Return JSON with "message" only and "actions": [].
        Context: \(context.compactJSON())
        """
    }

    static func localOpener(context: ChatSessionContext) -> String {
        let readiness = context.readinessScore.map { "\($0)%" } ?? "not available yet"
        var opener = "How are you feeling today? Your readiness is about \(readiness)."
        if !context.wearSummaryLines.isEmpty {
            opener += " Wear is elevated on: \(context.wearSummaryLines.prefix(3).joined(separator: ", "))."
        } else if !context.soreOrInjuredParts.isEmpty {
            opener += " You have marked areas on your Body Map—tell me if anything changed."
        } else {
            opener += " Say if a joint is sore or if something feels better."
        }
        return opener
    }
}
