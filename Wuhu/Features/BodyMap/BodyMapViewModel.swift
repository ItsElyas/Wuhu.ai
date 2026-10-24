import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class BodyMapViewModel {
    var selectedPart: BodyPart?
    var showList = false
    var showFront = true
    var range: BodyMapRange = .daily
    var loadError: String?

    enum BodyMapRange: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }

    func status(for part: BodyPart, in records: [BodyPartStatusRecord]) -> BodyPartStatusRecord? {
        records.first { $0.part == part && $0.status != .healthy }
    }

    func effectiveStatus(for part: BodyPart, in records: [BodyPartStatusRecord]) -> (BodyStatus, Double) {
        guard let record = records.first(where: { $0.part == part }) else {
            return (.healthy, 0)
        }
        if record.status == .worked {
            let decayed = WorkoutLoadMapper.decayedIntensity(
                base: record.intensity,
                hoursSince: record.hoursSinceUpdate
            )
            if decayed <= 0.05 { return (.healthy, 0) }
            return (.worked, decayed)
        }
        return (record.status, record.intensity)
    }

    func weeklyLoad(for part: BodyPart, workouts: [WorkoutRecord]) -> Double {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return workouts
            .filter { $0.startDate >= weekStart }
            .filter { $0.musclesWorked.contains(part) || WorkoutLoadMapper.parts(forWorkoutType: $0.type).contains(part) }
            .reduce(0.0) { partial, workout in
                partial + WorkoutLoadMapper.intensity(
                    durationMinutes: workout.durationMinutes,
                    averageHeartRate: workout.averageHeartRate
                )
            }
    }

    func updateStatus(
        part: BodyPart,
        status: BodyStatus,
        severity: Int,
        note: String?,
        records: inout [BodyPartStatusRecord],
        context: ModelContext
    ) {
        if let existing = records.first(where: { $0.part == part }) {
            if status == .healthy {
                existing.status = .healthy
                existing.intensity = 0
                existing.note = nil
                existing.updatedAt = .now
            } else {
                // Selecting without change should do nothing — caller compares first.
                if existing.status == status,
                   existing.severity == severity,
                   existing.note == note {
                    return
                }
                if existing.status != status {
                    existing.startedAt = .now
                }
                existing.status = status
                existing.severity = severity
                existing.note = note
                existing.sourceRaw = BodyStatusSource.manual.rawValue
                existing.intensity = status == .injured ? 1 : Double(severity) / 5.0
                existing.updatedAt = .now
            }
        } else if status != .healthy {
            let record = BodyPartStatusRecord(
                part: part,
                status: status,
                severity: severity,
                note: note,
                source: .manual,
                intensity: status == .injured ? 1 : Double(severity) / 5.0
            )
            context.insert(record)
            records.append(record)
        }
        try? context.save()
    }
}
