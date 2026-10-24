import Foundation
import SwiftData

enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

@Model
final class ChatMessage {
    var id: UUID
    var roleRaw: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), role: ChatRole, content: String, createdAt: Date = .now) {
        self.id = id
        self.roleRaw = role.rawValue
        self.content = content
        self.createdAt = createdAt
    }

    var role: ChatRole {
        ChatRole(rawValue: roleRaw) ?? .user
    }
}
