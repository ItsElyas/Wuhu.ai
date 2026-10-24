import Foundation
import SwiftData

/// Fills the demo store with realistic sample data: Body Map statuses, Workout Hub history
/// (lifting and running with real sets, weights, splits, and pace), and a short chat exchange.
/// Only ever runs against the separate in-memory demo container.
@MainActor
enum DemoDataSeeder {

    static func seed(into context: ModelContext, now: Date = .now) {
        seedBodyMap(context, now: now)
        seedLifting(context, now: now)
        seedRunning(context, now: now)
        seedChat(context, now: now)
        try? context.save()
    }

    // MARK: - Body Map

    private static func seedBodyMap(_ context: ModelContext, now: Date) {
        let day: TimeInterval = 86_400
        context.insert(BodyPartStatusRecord(
            part: .rightKnee, status: .injured, severity: 3,
            note: "Sharp pain on the downhill section of my long run",
            startedAt: now.addingTimeInterval(-3 * day), updatedAt: now.addingTimeInterval(-1 * day),
            source: .manual
        ))
        context.insert(BodyPartStatusRecord(
            part: .leftShoulder, status: .sore, severity: 2,
            note: "Tight after bench day",
            startedAt: now.addingTimeInterval(-1 * day), updatedAt: now.addingTimeInterval(-1 * day),
            source: .manual
        ))
        for part in [BodyPart.leftQuad, .rightQuad, .glutes] {
            context.insert(BodyPartStatusRecord(
                part: part, status: .worked, severity: 2,
                startedAt: now.addingTimeInterval(-1 * day), updatedAt: now.addingTimeInterval(-1 * day),
                source: .autoWorkout, intensity: 0.65
            ))
        }
    }

    // MARK: - Workout Hub: lifting

    private struct DemoLift {
        var name: String
        var reps: String
        var intensity: String
        /// (weight lbs, reps) per set.
        var sets: [(Double, Int)]
    }

    private static func seedLifting(_ context: ModelContext, now: Date) {
        let sessions: [(daysAgo: Int, title: String, focus: String, minutes: Double, lifts: [DemoLift])] = [
            (1, "Monday · Competition Squat & Bench Volume", "Competition Squat & Bench Volume", 72, [
                DemoLift(name: "Competition Low-Bar Squat", reps: "3", intensity: "85% 1RM",
                         sets: [(275, 3), (285, 3), (285, 3), (295, 3), (295, 2)]),
                DemoLift(name: "Paused Bench Press", reps: "3", intensity: "85% 1RM",
                         sets: [(195, 3), (205, 3), (205, 3), (205, 3), (210, 3)]),
            ]),
            (4, "Friday · Secondary Bench & Tricep Lockout Volume", "Secondary Bench & Tricep Lockout Volume", 58, [
                DemoLift(name: "Close Grip Bench Press", reps: "5", intensity: "77.5% 1RM",
                         sets: [(175, 5), (185, 5), (185, 5), (185, 4)]),
                DemoLift(name: "Barbell Seal Row", reps: "8", intensity: "77.5% 1RM",
                         sets: [(145, 8), (155, 8), (155, 8), (155, 7)]),
            ]),
            (6, "Thursday · Competition Deadlift & Secondary Squat", "Competition Deadlift & Secondary Squat", 81, [
                DemoLift(name: "Competition Deadlift", reps: "2", intensity: "87.5% 1RM",
                         sets: [(365, 2), (385, 2), (385, 2), (395, 2)]),
                DemoLift(name: "Pause Squats (2s hole)", reps: "4", intensity: "87.5% 1RM",
                         sets: [(225, 4), (235, 4), (235, 4), (235, 4)]),
            ]),
            (8, "Monday · Competition Squat & Bench Volume", "Competition Squat & Bench Volume", 69, [
                DemoLift(name: "Competition Low-Bar Squat", reps: "3", intensity: "85% 1RM",
                         sets: [(265, 3), (275, 3), (275, 3), (285, 3), (285, 3)]),
                DemoLift(name: "Paused Bench Press", reps: "3", intensity: "85% 1RM",
                         sets: [(190, 3), (195, 3), (200, 3), (200, 3), (200, 3)]),
            ]),
            (2, "Explosive Day · Power Clean & Upper Back", "Explosive Power & Upper Back", 54, [
                DemoLift(name: "Power Clean", reps: "3", intensity: "RPE 8",
                         sets: [(155, 3), (165, 3), (175, 3), (185, 2), (185, 2)]),
                DemoLift(name: "Barbell Seal Row", reps: "8", intensity: "RPE 7.5",
                         sets: [(145, 8), (150, 8), (155, 8)]),
            ]),
            (9, "Explosive Day · Power Clean & Upper Back", "Explosive Power & Upper Back", 50, [
                DemoLift(name: "Power Clean", reps: "3", intensity: "RPE 8",
                         sets: [(155, 3), (170, 3), (180, 3), (190, 2)]),
                DemoLift(name: "Barbell Seal Row", reps: "8", intensity: "RPE 7.5",
                         sets: [(135, 8), (145, 8), (145, 8)]),
            ]),
            (11, "Friday · Secondary Bench & Tricep Lockout Volume", "Secondary Bench & Tricep Lockout Volume", 55, [
                DemoLift(name: "Close Grip Bench Press", reps: "5", intensity: "77.5% 1RM",
                         sets: [(165, 5), (175, 5), (175, 5), (180, 4)]),
                DemoLift(name: "Skullcrushers", reps: "10", intensity: "RPE 7.5",
                         sets: [(65, 10), (70, 10), (70, 9)]),
            ]),
            (13, "Thursday · Competition Deadlift & Secondary Squat", "Competition Deadlift & Secondary Squat", 78, [
                DemoLift(name: "Competition Deadlift", reps: "2", intensity: "87.5% 1RM",
                         sets: [(345, 2), (365, 2), (375, 2), (375, 2)]),
                DemoLift(name: "Pause Squats (2s hole)", reps: "4", intensity: "87.5% 1RM",
                         sets: [(215, 4), (225, 4), (225, 4), (225, 4)]),
            ]),
            (16, "Monday · Competition Squat & Bench Volume", "Competition Squat & Bench Volume", 70, [
                DemoLift(name: "Competition Low-Bar Squat", reps: "3", intensity: "85% 1RM",
                         sets: [(255, 3), (265, 3), (275, 3), (275, 3), (275, 3)]),
                DemoLift(name: "Paused Bench Press", reps: "3", intensity: "85% 1RM",
                         sets: [(185, 3), (190, 3), (195, 3), (195, 3), (195, 3)]),
            ]),
        ]

        for entry in sessions {
            let start = startDate(daysAgo: entry.daysAgo, hour: 18, now: now)
            let regimen = HubRegimenBuilder.Regimen(
                kind: .lifting, title: entry.title, focus: entry.focus,
                cue: "Logged in demo mode", isRestDay: false,
                lifts: entry.lifts.map {
                    HubRegimenBuilder.LiftItem(name: $0.name, sets: $0.sets.count, reps: $0.reps, intensity: $0.intensity)
                },
                runs: []
            )
            let session = HubSessionService.start(regimen, in: context, startedAt: start, startLiveActivity: false)
            for (exercise, lift) in zip(session.sortedExercises, entry.lifts) {
                for (set, logged) in zip(exercise.sortedSets, lift.sets) {
                    set.weightLbs = logged.0
                    set.usesBodyweight = false
                    set.reps = logged.1
                    set.isCompleted = true
                }
            }
            HubSessionService.finish(session, in: context, endedAt: start.addingTimeInterval(entry.minutes * 60))
        }
    }

    // MARK: - Workout Hub: running

    private static func seedRunning(_ context: ModelContext, now: Date) {
        // Threshold repeats: 4 × 1 mile with real splits.
        let thresholdStart = startDate(daysAgo: 3, hour: 7, now: now)
        let threshold = HubRegimenBuilder.Regimen(
            kind: .running, title: "Monday · Threshold Cruise Intervals & VO2 Max",
            focus: "Threshold Cruise Intervals & VO2 Max", cue: "Comfortably hard pace; relaxed shoulders, 175+ cadence",
            isRestDay: false, lifts: [],
            runs: (1...4).map {
                HubRegimenBuilder.RunItem(label: "Threshold Tempo Repeats · Rep \($0) of 4",
                                          target: "1 Mile · Zone 4 / RPE 8", plannedMiles: 1)
            }
        )
        let splits: [(Double, Double, Double)] = [(1.0, 425, 168), (1.0, 421, 171), (1.0, 418, 173), (1.0, 414, 176)]
        logRun(threshold, splits: splits, start: thresholdStart, minutes: 38, context: context)

        // Easy aerobic run.
        let easyStart = startDate(daysAgo: 5, hour: 7, now: now)
        let easy = HubRegimenBuilder.Regimen(
            kind: .running, title: "Friday · Mid-Distance Aerobic Flush Run",
            focus: "Mid-Distance Aerobic Flush Run", cue: "Consistent rhythm; conversational nasal breathing",
            isRestDay: false, lifts: [],
            runs: [HubRegimenBuilder.RunItem(label: "Steady Aerobic Base Run", target: "40-45 mins · Zone 2", plannedMiles: nil)]
        )
        logRun(easy, splits: [(4.6, 2_430, 146)], start: easyStart, minutes: 42, context: context)

        // Long run.
        let longStart = startDate(daysAgo: 10, hour: 8, now: now)
        let long = HubRegimenBuilder.Regimen(
            kind: .running, title: "Saturday · Long Aerobic Base Run & Capillary Density",
            focus: "Long Aerobic Base Run & Capillary Density", cue: "Builds mitochondrial bed density and fuel efficiency",
            isRestDay: false, lifts: [],
            runs: [HubRegimenBuilder.RunItem(label: "Aerobic Base Long Run", target: "60-75 mins · Zone 2", plannedMiles: nil)]
        )
        logRun(long, splits: [(7.8, 4_190, 148)], start: longStart, minutes: 71, context: context)
    }

    /// splits: (miles, seconds, avg HR) per segment.
    private static func logRun(
        _ regimen: HubRegimenBuilder.Regimen,
        splits: [(Double, Double, Double)],
        start: Date,
        minutes: Double,
        context: ModelContext
    ) {
        let session = HubSessionService.start(regimen, in: context, startedAt: start, startLiveActivity: false)
        for (segment, split) in zip(session.sortedSegments, splits) {
            segment.distanceMiles = split.0
            segment.durationSeconds = split.1
            segment.averageHeartRate = split.2
            segment.isCompleted = true
        }
        HubSessionService.finish(session, in: context, endedAt: start.addingTimeInterval(minutes * 60))
    }

    // MARK: - Chat

    private static func seedChat(_ context: ModelContext, now: Date) {
        let base = now.addingTimeInterval(-86_400)
        context.insert(ChatMessage(role: .user, content: "My right knee has been hurting since my long run.", createdAt: base))
        context.insert(ChatMessage(
            role: .assistant,
            content: "Sorry to hear that. I'm logging your right knee as injured on your Wear & Tear so we plan around it. Skip running and deep knee bends for now, and check the heal tips on your Body Map. If it's still sharp or swollen after a week, see a physical therapist.",
            createdAt: base.addingTimeInterval(30)
        ))
    }

    private static func startDate(daysAgo: Int, hour: Int, now: Date) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}
