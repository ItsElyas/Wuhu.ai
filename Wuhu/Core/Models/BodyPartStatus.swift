import Foundation
import SwiftData

enum BodyStatus: String, Codable, CaseIterable, Sendable {
    case healthy
    case worked
    case sore
    case injured
}

enum BodyStatusSource: String, Codable, Sendable {
    case manual
    case autoWorkout
}

/// On-device wear-and-tear status for one body region.
@Model
final class BodyPartStatusRecord {
    var partRaw: String
    var statusRaw: String
    var severity: Int
    var note: String?
    var startedAt: Date
    var updatedAt: Date
    var sourceRaw: String
    /// 0...1 intensity for worked / sore yellow fade.
    var intensity: Double

    init(
        part: BodyPart,
        status: BodyStatus,
        severity: Int = 1,
        note: String? = nil,
        startedAt: Date = .now,
        updatedAt: Date = .now,
        source: BodyStatusSource = .manual,
        intensity: Double = 1.0
    ) {
        self.partRaw = part.rawValue
        self.statusRaw = status.rawValue
        self.severity = min(5, max(1, severity))
        self.note = note
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.sourceRaw = source.rawValue
        self.intensity = min(1, max(0, intensity))
    }

    var part: BodyPart {
        BodyPart(rawValue: partRaw) ?? .chest
    }

    var status: BodyStatus {
        get { BodyStatus(rawValue: statusRaw) ?? .healthy }
        set { statusRaw = newValue.rawValue }
    }

    var source: BodyStatusSource {
        BodyStatusSource(rawValue: sourceRaw) ?? .manual
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startedAt, to: .now).day ?? 0
    }

    var hoursSinceUpdate: Double {
        Date.now.timeIntervalSince(updatedAt) / 3600
    }
}

@Model
final class CachedScoreResult {
    var id: UUID
    var snapshotHash: String
    var dayKey: String
    var jsonData: Data
    var createdAt: Date
    var usedLocalFallback: Bool

    init(
        id: UUID = UUID(),
        snapshotHash: String,
        dayKey: String,
        jsonData: Data,
        createdAt: Date = .now,
        usedLocalFallback: Bool = false
    ) {
        self.id = id
        self.snapshotHash = snapshotHash
        self.dayKey = dayKey
        self.jsonData = jsonData
        self.createdAt = createdAt
        self.usedLocalFallback = usedLocalFallback
    }
}
