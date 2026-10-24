import Foundation
import SwiftData

enum WorkoutIntensity: String, Codable, CaseIterable, Sendable {
    case easy
    case moderate
    case hard
}

enum WorkoutSource: String, Codable, Sendable {
    case manual
    case healthKit
}

/// In-app or imported workout stored in SwiftData.
@Model
final class WorkoutRecord {
    var id: UUID
    var type: String
    var startDate: Date
    var durationMinutes: Double
    var calories: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var intensity: String
    var notes: String?
    var sourceRaw: String
    var musclesWorkedRaw: [String]
    var createdAt: Date
    /// Logged distance (Workout Hub runs). `nil` for imports and lifts.
    var distanceMiles: Double?
    /// Workout Hub session this record was written from, if any.
    var hubSessionID: UUID?

    init(
        id: UUID = UUID(),
        type: String,
        startDate: Date,
        durationMinutes: Double,
        calories: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        intensity: WorkoutIntensity = .moderate,
        notes: String? = nil,
        source: WorkoutSource = .manual,
        musclesWorked: [BodyPart] = [],
        createdAt: Date = .now,
        distanceMiles: Double? = nil,
        hubSessionID: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.durationMinutes = durationMinutes
        self.calories = calories
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.intensity = intensity.rawValue
        self.notes = notes
        self.sourceRaw = source.rawValue
        self.musclesWorkedRaw = musclesWorked.map(\.rawValue)
        self.createdAt = createdAt
        self.distanceMiles = distanceMiles
        self.hubSessionID = hubSessionID
    }

    var workoutIntensity: WorkoutIntensity {
        WorkoutIntensity(rawValue: intensity) ?? .moderate
    }

    var source: WorkoutSource {
        WorkoutSource(rawValue: sourceRaw) ?? .manual
    }

    var musclesWorked: [BodyPart] {
        musclesWorkedRaw.compactMap(BodyPart.init(rawValue:))
    }

    /// Deduplicate HealthKit and manual entries by start time + type.
    static func isDuplicate(_ a: WorkoutRecord, _ b: WorkoutRecord, toleranceSeconds: TimeInterval = 60) -> Bool {
        a.type.localizedCaseInsensitiveCompare(b.type) == .orderedSame
            && abs(a.startDate.timeIntervalSince(b.startDate)) <= toleranceSeconds
    }

    static func mergeDeduplicating(_ workouts: [WorkoutRecord]) -> [WorkoutRecord] {
        var result: [WorkoutRecord] = []
        for workout in workouts.sorted(by: { $0.startDate > $1.startDate }) {
            if result.contains(where: { isDuplicate($0, workout) }) { continue }
            result.append(workout)
        }
        return result
    }
}
