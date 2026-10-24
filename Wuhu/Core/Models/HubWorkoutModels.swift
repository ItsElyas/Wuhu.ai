import Foundation
import SwiftData

// SwiftData models for Workout Hub: a session (running or lifting) owns exercises/sets or run segments.
// Finished sessions are the workout log history; each also writes a `WorkoutRecord` so wear,
// weekly stats, and WSL pick it up.

enum HubWorkoutKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case running
    case lifting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .running: return "Running"
        case .lifting: return "Lifting"
        }
    }

    var symbol: String {
        switch self {
        case .running: return "figure.run"
        case .lifting: return "dumbbell.fill"
        }
    }

    /// Regimen bank this kind draws from.
    var sport: AthleteOnboardingEngine.SportDiscipline {
        switch self {
        case .running: return .running
        case .lifting: return .powerlifting
        }
    }

    /// `WorkoutRecord.type` written on finish (matches wear mapper and weekly builders).
    var recordType: String {
        switch self {
        case .running: return "running"
        case .lifting: return "strength"
        }
    }
}

/// One workout from Start to Finish.
@Model
final class HubSession {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var title: String
    var focus: String?
    var cue: String?
    var startedAt: Date
    /// `nil` while the workout is in progress.
    var endedAt: Date?
    var notes: String?
    @Relationship(deleteRule: .cascade, inverse: \HubExercise.session)
    var exercises: [HubExercise]
    @Relationship(deleteRule: .cascade, inverse: \HubRunSegment.session)
    var runSegments: [HubRunSegment]

    init(
        id: UUID = UUID(),
        kind: HubWorkoutKind,
        title: String,
        focus: String? = nil,
        cue: String? = nil,
        startedAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.focus = focus
        self.cue = cue
        self.startedAt = startedAt
        self.endedAt = nil
        self.exercises = []
        self.runSegments = []
    }

    var kind: HubWorkoutKind { HubWorkoutKind(rawValue: kindRaw) ?? .lifting }
    var isActive: Bool { endedAt == nil }

    var sortedExercises: [HubExercise] { exercises.sorted { $0.sortIndex < $1.sortIndex } }
    var sortedSegments: [HubRunSegment] { runSegments.sorted { $0.index < $1.index } }

    var durationMinutes: Double {
        max(0, (endedAt ?? .now).timeIntervalSince(startedAt) / 60)
    }

    /// Completed lifting volume (lbs × reps).
    var totalVolumeLbs: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + $1.volumeLbs }
    }

    var completedSetCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    var completedSegments: [HubRunSegment] {
        runSegments.filter { $0.isCompleted && ($0.distanceMiles ?? 0) > 0 }
    }

    var totalMiles: Double {
        completedSegments.compactMap(\.distanceMiles).reduce(0, +)
    }

    /// Total timed seconds across completed segments that have a time.
    var totalRunSeconds: Double {
        completedSegments.compactMap(\.durationSeconds).reduce(0, +)
    }

    /// Average pace (seconds per mile) over completed segments with both distance and time.
    var averagePaceSecondsPerMile: Double? {
        let timed = completedSegments.filter { ($0.durationSeconds ?? 0) > 0 }
        let miles = timed.compactMap(\.distanceMiles).reduce(0, +)
        let seconds = timed.compactMap(\.durationSeconds).reduce(0, +)
        guard miles > 0, seconds > 0 else { return nil }
        return seconds / miles
    }
}

@Model
final class HubExercise {
    @Attribute(.unique) var id: UUID
    /// Start-of-day for the session (local calendar).
    var sessionDay: Date
    var name: String
    var sortIndex: Int
    /// Regimen target, e.g. sets 5 and reps "3".
    var targetSets: Int?
    var targetReps: String?
    var targetIntensity: String?
    @Relationship(deleteRule: .cascade, inverse: \HubSetLog.exercise)
    var sets: [HubSetLog]
    var session: HubSession?

    init(
        id: UUID = UUID(),
        sessionDay: Date,
        name: String,
        sortIndex: Int,
        targetSets: Int? = nil,
        targetReps: String? = nil,
        targetIntensity: String? = nil,
        sets: [HubSetLog] = []
    ) {
        self.id = id
        self.sessionDay = sessionDay
        self.name = name
        self.sortIndex = sortIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetIntensity = targetIntensity
        self.sets = sets
    }

    var sortedSets: [HubSetLog] { sets.sorted { $0.setNumber < $1.setNumber } }

    /// "5 × 3 · 85% 1RM" style target line.
    var targetLine: String? {
        var parts: [String] = []
        if let targetSets, let targetReps { parts.append("\(targetSets) × \(targetReps)") }
        else if let targetReps { parts.append(targetReps) }
        if let targetIntensity, !targetIntensity.isEmpty { parts.append(targetIntensity) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

@Model
final class HubSetLog {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    /// `nil` with `usesBodyweight == true` displays as BW.
    var weightLbs: Double?
    var usesBodyweight: Bool
    var reps: Int
    var isCompleted: Bool
    var exercise: HubExercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weightLbs: Double?,
        usesBodyweight: Bool = false,
        reps: Int,
        isCompleted: Bool = false,
        exercise: HubExercise? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightLbs = weightLbs
        self.usesBodyweight = usesBodyweight
        self.reps = reps
        self.isCompleted = isCompleted
        self.exercise = exercise
    }

    var weightDisplay: String {
        if usesBodyweight { return "BW" }
        if let weightLbs { return HubFormat.weight(weightLbs) }
        return "—"
    }

    var volumeLbs: Double {
        guard isCompleted else { return 0 }
        let load = usesBodyweight ? 0 : (weightLbs ?? 0)
        return load * Double(reps)
    }
}

/// One running interval or block (e.g. "Rep 2 of 4 · 1 Mile").
@Model
final class HubRunSegment {
    @Attribute(.unique) var id: UUID
    var index: Int
    var label: String
    var target: String?
    var distanceMiles: Double?
    var durationSeconds: Double?
    var averageHeartRate: Double?
    var isCompleted: Bool
    var session: HubSession?

    init(
        id: UUID = UUID(),
        index: Int,
        label: String,
        target: String? = nil,
        distanceMiles: Double? = nil,
        durationSeconds: Double? = nil,
        averageHeartRate: Double? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.index = index
        self.label = label
        self.target = target
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
        self.averageHeartRate = averageHeartRate
        self.isCompleted = isCompleted
    }

    /// Seconds per mile when both distance and time are logged.
    var paceSecondsPerMile: Double? {
        guard let distanceMiles, distanceMiles > 0, let durationSeconds, durationSeconds > 0 else { return nil }
        return durationSeconds / distanceMiles
    }
}

enum HubWorkoutCalendar {
    static func startOfDay(_ date: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
