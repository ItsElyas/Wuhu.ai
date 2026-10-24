import Foundation
import SwiftData

/// Creates, finishes, and discards Workout Hub sessions. All writes go through here.
@MainActor
enum HubSessionService {

    /// Starts a session from a regimen. Lift weights are pre-filled from the last time the
    /// user logged the same exercise, so the log reflects what they actually lift.
    @discardableResult
    static func start(
        _ regimen: HubRegimenBuilder.Regimen,
        in context: ModelContext,
        startedAt: Date = .now,
        startLiveActivity: Bool = true
    ) -> HubSession {
        let session = HubSession(kind: regimen.kind, title: regimen.title, focus: regimen.focus, cue: regimen.cue, startedAt: startedAt)
        context.insert(session)
        let day = HubWorkoutCalendar.startOfDay(session.startedAt)

        for (index, lift) in regimen.lifts.enumerated() {
            let exercise = HubExercise(
                sessionDay: day, name: lift.name, sortIndex: index,
                targetSets: lift.sets, targetReps: lift.reps, targetIntensity: lift.intensity
            )
            exercise.session = session
            context.insert(exercise)
            let previous = lastWorkingSet(named: lift.name, in: context)
            let reps = Int(lift.reps.prefix { $0.isNumber }) ?? previous?.reps ?? 8
            for number in 1...lift.sets {
                let set = HubSetLog(
                    setNumber: number,
                    weightLbs: previous?.weightLbs,
                    usesBodyweight: previous?.usesBodyweight ?? false,
                    reps: reps,
                    exercise: exercise
                )
                context.insert(set)
                exercise.sets.append(set)
            }
            session.exercises.append(exercise)
        }

        for (index, run) in regimen.runs.enumerated() {
            let segment = HubRunSegment(index: index, label: run.label, target: run.target, distanceMiles: run.plannedMiles)
            segment.session = session
            context.insert(segment)
            session.runSegments.append(segment)
        }

        try? context.save()
        if startLiveActivity {
            WorkoutLiveActivityController.start(session)
        }
        return session
    }

    static func addExercise(named name: String, to session: HubSession, in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let exercise = HubExercise(
            sessionDay: HubWorkoutCalendar.startOfDay(session.startedAt),
            name: trimmed,
            sortIndex: (session.exercises.map(\.sortIndex).max() ?? -1) + 1
        )
        exercise.session = session
        context.insert(exercise)
        session.exercises.append(exercise)
        addSet(to: exercise, in: context)
    }

    static func addSet(to exercise: HubExercise, in context: ModelContext) {
        let last = exercise.sortedSets.last ?? lastWorkingSet(named: exercise.name, in: context).map {
            HubSetLog(setNumber: 0, weightLbs: $0.weightLbs, usesBodyweight: $0.usesBodyweight, reps: $0.reps)
        }
        let set = HubSetLog(
            setNumber: (exercise.sets.map(\.setNumber).max() ?? 0) + 1,
            weightLbs: last?.weightLbs,
            usesBodyweight: last?.usesBodyweight ?? false,
            reps: last?.reps ?? 8,
            exercise: exercise
        )
        context.insert(set)
        exercise.sets.append(set)
        try? context.save()
    }

    static func addSegment(to session: HubSession, in context: ModelContext) {
        let index = (session.runSegments.map(\.index).max() ?? -1) + 1
        let segment = HubRunSegment(index: index, label: "Run \(index + 1)", target: nil)
        segment.session = session
        context.insert(segment)
        session.runSegments.append(segment)
        try? context.save()
    }

    /// Ends the session and writes a matching `WorkoutRecord` (used by wear, weekly stats, and WSL).
    /// Returns `false` when nothing was logged (no completed sets / segments) so the UI can warn.
    @discardableResult
    static func finish(_ session: HubSession, in context: ModelContext, endedAt: Date = .now) -> Bool {
        let hasData = session.kind == .lifting ? session.completedSetCount > 0 : !session.completedSegments.isEmpty
        session.endedAt = endedAt

        let record = WorkoutRecord(
            type: session.kind.recordType,
            startDate: session.startedAt,
            durationMinutes: max(1, session.durationMinutes.rounded()),
            averageHeartRate: averageHeartRate(session),
            intensity: .moderate,
            notes: summary(session),
            source: .manual,
            musclesWorked: muscles(for: session),
            distanceMiles: session.kind == .running && session.totalMiles > 0 ? session.totalMiles : nil,
            hubSessionID: session.id
        )
        context.insert(record)
        try? context.save()
        WorkoutLiveActivityController.end(sessionID: session.id)
        return hasData
    }

    /// Deletes the session and its linked `WorkoutRecord`.
    static func delete(_ session: HubSession, in context: ModelContext) {
        let id = session.id
        WorkoutLiveActivityController.end(sessionID: id)
        let linked = (try? context.fetch(FetchDescriptor<WorkoutRecord>(predicate: #Predicate { $0.hubSessionID == id }))) ?? []
        linked.forEach(context.delete)
        context.delete(session)
        try? context.save()
    }

    // MARK: - Helpers

    /// Most recent completed, weighted set for an exercise name in any finished session.
    static func lastWorkingSet(named name: String, in context: ModelContext) -> HubSetLog? {
        let target = name.lowercased()
        let descriptor = FetchDescriptor<HubSetLog>(predicate: #Predicate { $0.isCompleted })
        let sets = (try? context.fetch(descriptor)) ?? []
        return sets
            .filter { $0.exercise?.name.lowercased() == target && $0.exercise?.session?.isActive == false }
            .max { ($0.exercise?.session?.startedAt ?? .distantPast, $0.setNumber) < ($1.exercise?.session?.startedAt ?? .distantPast, $1.setNumber) }
    }

    /// "Squat 3 sets, top 275×3 · Bench 3 sets, top 205×5" or "3.10 mi · 8:12 /mi".
    static func summary(_ session: HubSession) -> String {
        switch session.kind {
        case .lifting:
            let lines = session.sortedExercises.compactMap { exercise -> String? in
                let done = exercise.sets.filter(\.isCompleted)
                guard !done.isEmpty else { return nil }
                let top = done.max { ($0.weightLbs ?? 0) < ($1.weightLbs ?? 0) }
                let topText = top.map { "\($0.weightDisplay)×\($0.reps)" } ?? ""
                return "\(exercise.name) \(done.count) sets, top \(topText)"
            }
            return lines.isEmpty ? "No sets completed" : lines.joined(separator: " · ")
        case .running:
            var parts = [HubFormat.miles(session.totalMiles)]
            if let pace = session.averagePaceSecondsPerMile { parts.append(HubFormat.pace(pace)) }
            return parts.joined(separator: " · ")
        }
    }

    private static func averageHeartRate(_ session: HubSession) -> Double? {
        let values = session.completedSegments.compactMap(\.averageHeartRate)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Only parts the mapper actually knows for the logged exercise names (no generic fallback).
    private static func muscles(for session: HubSession) -> [BodyPart] {
        switch session.kind {
        case .running:
            return WorkoutLoadMapper.parts(forWorkoutType: "running")
        case .lifting:
            var parts: [BodyPart] = []
            for exercise in session.exercises where exercise.sets.contains(where: \.isCompleted) {
                let lower = exercise.name.lowercased()
                let matches = WorkoutLoadMapper.typeToParts
                    .filter { $0.key != "other" && lower.contains($0.key) }
                    .flatMap(\.value)
                for part in matches where !parts.contains(part) { parts.append(part) }
            }
            return parts.isEmpty ? WorkoutLoadMapper.parts(forWorkoutType: "strength") : parts
        }
    }
}
