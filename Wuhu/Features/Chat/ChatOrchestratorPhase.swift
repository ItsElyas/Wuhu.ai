import Foundation

enum ChatOrchestratorPhase: Equatable {
    case idle
    case readingHealth
    case thinking
    case updating

    /// User-visible status under the chat input / typing row.
    var statusText: String? {
        switch self {
        case .idle:
            return nil
        case .readingHealth:
            return "reading your past health..."
        case .thinking:
            return "thinking..."
        case .updating:
            return "updating..."
        }
    }
}
