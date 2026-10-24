import Foundation
import SwiftData

/// Applies validated chat wear actions to SwiftData and refreshes derived wear.
@MainActor
enum ChatWearTearExecutor {
    struct Outcome: Sendable {
        var applied: [ChatWearTearAction]
        var skipped: [(ChatWearTearAction, String)]
    }

    static func apply(
        actions: [ChatWearTearAction],
        lastUserMessage: String,
        modelContext: ModelContext,
        app: AppEnvironment
    ) -> Outcome {
        var applied: [ChatWearTearAction] = []
        var skipped: [(ChatWearTearAction, String)] = []
        let lower = lastUserMessage.lowercased()
        var records = (try? modelContext.fetch(FetchDescriptor<BodyPartStatusRecord>())) ?? []

        for action in actions {
            guard let part = BodyPartRegistry.resolvePart(action.part) else {
                skipped.append((action, "Unknown body part"))
                continue
            }
            if action.status == .injured, !ChatWearTearActionParser.userReportsInjury(in: lower) {
                skipped.append((action, "Injured status requires clear pain or injury in your message"))
                continue
            }

            let bodyStatus: BodyStatus
            switch action.status {
            case .healthy:
                bodyStatus = .healthy
            case .sore:
                bodyStatus = .sore
            case .injured:
                bodyStatus = .injured
            }

            let severity = min(5, max(1, action.severity ?? (bodyStatus == .injured ? 2 : 3)))

            if let existing = records.first(where: { $0.part == part }) {
                if bodyStatus == .healthy {
                    existing.status = .healthy
                    existing.intensity = 0
                    existing.note = nil
                    existing.updatedAt = .now
                } else {
                    if existing.status != bodyStatus {
                        existing.startedAt = .now
                    }
                    existing.status = bodyStatus
                    existing.severity = severity
                    existing.note = action.note
                    existing.sourceRaw = BodyStatusSource.manual.rawValue
                    existing.intensity = bodyStatus == .injured ? 1 : Double(severity) / 5.0
                    existing.updatedAt = .now
                }
            } else if bodyStatus != .healthy {
                let record = BodyPartStatusRecord(
                    part: part,
                    status: bodyStatus,
                    severity: severity,
                    note: action.note,
                    source: .manual,
                    intensity: bodyStatus == .injured ? 1 : Double(severity) / 5.0
                )
                modelContext.insert(record)
                records.append(record)
            }

            applied.append(action)
        }

        try? modelContext.save()
        let workoutRecords = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        app.refreshWear(bodyRecords: records, workoutRecords: workoutRecords)

        return Outcome(applied: applied, skipped: skipped)
    }
}

extension BodyPartRegistry {
    /// Accepts enum rawValue or a close display-name match.
    static func resolvePart(_ token: String) -> BodyPart? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = BodyPart(rawValue: trimmed) { return exact }
        let normalized = trimmed.lowercased().replacingOccurrences(of: " ", with: "")
        for part in BodyPart.allCases {
            let display = part.displayName.lowercased().replacingOccurrences(of: " ", with: "")
            if display == normalized || part.rawValue.lowercased() == normalized {
                return part
            }
        }
        return nil
    }
}
