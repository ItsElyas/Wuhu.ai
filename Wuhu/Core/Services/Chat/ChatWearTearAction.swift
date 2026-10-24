import Foundation

/// Structured body-map update proposed by the chat orchestrator (validated before apply).
struct ChatWearTearAction: Codable, Sendable, Equatable {
    enum Status: String, Codable, Sendable {
        case healthy
        case sore
        case injured
    }

    var part: String
    var status: Status
    var severity: Int?
    var note: String?
}

struct ChatOrchestratorResult: Sendable, Equatable {
    var message: String
    var actions: [ChatWearTearAction]
}
