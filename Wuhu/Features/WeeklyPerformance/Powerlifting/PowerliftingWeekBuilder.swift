import Foundation

struct PowerliftingWeekDisplay {
    var dateRange: String
    var stats: [WeeklyMetric]
    var lifts: [LiftProgress]
    var prs: [LiftRecord]
    var lastWorkoutSubtitle: String
    var lastWorkoutRows: [LiftRecord]
    var placeholderMessage: String?
}

/// Weekly powerlifting stats from finished Workout Hub lifting sessions (real sets and weights),
/// plus training time from other strength workouts (e.g. Apple Health imports).
enum PowerliftingWeekBuilder {
    private static let strengthTypes: Set<String> = ["strength", "traditionalstrengthtraining", "functionalstrengthtraining"]

    /// The four tracked lifts and the exercise-name keywords that count toward each.
    private enum TrackedLift: String, CaseIterable {
        case bench, squat, deadlift, clean

        var title: String {
            switch self {
            case .bench: return "Bench Press"
            case .squat: return "Squat"
            case .deadlift: return "Deadlift"
            case .clean: return "Power Clean"
            }
        }

        var symbol: String {
            switch self {
            case .bench: return "figure.strengthtraining.traditional"
            case .squat: return "figure.strengthtraining.functional"
            case .deadlift, .clean: return "dumbbell.fill"
            }
        }

        var tint: UInt32 {
            switch self {
            case .bench: return 0xE15B9A
            case .squat: return 0x7A5AF8
            case .deadlift: return 0x6366F1
            case .clean: return 0x14B8A6
            }
        }

        static func match(_ exerciseName: String) -> TrackedLift? {
            let name = exerciseName.lowercased()
            if name.contains("clean") { return .clean }
            if name.contains("deadlift") && !name.contains("romanian") { return .deadlift }
            if name.contains("squat") && !name.contains("split") { return .squat }
            if name.contains("bench") && !name.contains("dumbbell") { return .bench }
            return nil
        }
    }

    /// A completed, weighted set with its session date.
    private struct WorkingSet {
        var lift: TrackedLift?
        var weight: Double
        var reps: Int
        var date: Date
    }

    static func make(
        sessions: [HubSession],
        logged: [WorkoutRecord],
        profileWeightKg: Double?,
        ending: Date = .now
    ) -> PowerliftingWeekDisplay {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: ending)
        guard let start = calendar.date(byAdding: .day, value: -6, to: endDay),
              let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay),
              let previousStart = calendar.date(byAdding: .day, value: -13, to: endDay) else {
            return placeholder(ending: ending)
        }
        let range = "\(monthDay(start)) – \(monthDay(endDay))"

        let lifting = sessions.filter { $0.kind == .lifting && !$0.isActive }
        let week = lifting.filter { $0.startedAt >= start && $0.startedAt < endExclusive }
        let previous = lifting.filter { $0.startedAt >= previousStart && $0.startedAt < start }

        // Strength workouts not logged in Workout Hub still count toward training time.
        let otherWeek = logged.filter { isStrength($0.type) && $0.hubSessionID == nil && $0.startDate >= start && $0.startDate < endExclusive }
        let otherPrevious = logged.filter { isStrength($0.type) && $0.hubSessionID == nil && $0.startDate >= previousStart && $0.startDate < start }

        guard !week.isEmpty || !otherWeek.isEmpty else {
            return placeholder(ending: ending, dateRange: range)
        }

        let liftsCount = exerciseCount(week)
        let previousLifts = exerciseCount(previous)
        let volume = week.reduce(0) { $0 + $1.totalVolumeLbs }
        let previousVolume = previous.reduce(0) { $0 + $1.totalVolumeLbs }
        let minutes = week.reduce(0) { $0 + $1.durationMinutes } + otherWeek.reduce(0) { $0 + $1.durationMinutes }
        let previousMinutes = previous.reduce(0) { $0 + $1.durationMinutes } + otherPrevious.reduce(0) { $0 + $1.durationMinutes }

        var display = placeholder(ending: ending, dateRange: range)
        display.placeholderMessage = nil
        display.stats = [
            stat("lifts", "Total Lifts", liftsCount > 0 ? "\(liftsCount)" : "--", "dumbbell.fill", 0x7A5AF8,
                 delta(Double(liftsCount), Double(previousLifts), suffix: "", digits: 0)),
            stat("volume", "Total Volume", volume > 0 ? "\(HomeFormat.grouped(Int(volume.rounded()))) lbs" : "--", "flame.fill", 0xE1453F,
                 percentDelta(volume, previousVolume)),
            stat("time", "Total Training Time", formatDuration(minutes), "stopwatch.fill", 0x7A5AF8,
                 percentDelta(minutes, previousMinutes)),
            stat("weight", "Avg. Bodyweight", profileWeightKg.map { "\(Int(($0 * 2.20462).rounded())) lbs" } ?? "--", "scalemass.fill", 0x14B8A6,
                 ("—", "minus", true)),
        ]

        let allSets = workingSets(lifting)
        let weekSets = allSets.filter { $0.date >= start && $0.date < endExclusive }
        let previousSets = allSets.filter { $0.date >= previousStart && $0.date < start }

        display.lifts = TrackedLift.allCases.map { lift in
            let best = weekSets.filter { $0.lift == lift }.map(\.weight).max()
            let previousBest = previousSets.filter { $0.lift == lift }.map(\.weight).max()
            guard let best else { return liftSlot(lift) }
            let trend: (String, String, Bool) = previousBest.map { prior in
                let change = best - prior
                if abs(change) < 0.5 { return ("0 lbs", "minus", true) }
                return (String(format: "%+.0f lbs", change), change > 0 ? "arrow.up" : "arrow.down", change > 0)
            } ?? ("New", "sparkles", true)
            return LiftProgress(
                id: lift.rawValue, name: lift.title, value: "\(HubFormat.weight(best)) lbs",
                trend: trend.0, trendSymbol: trend.1, favorable: trend.2,
                systemImage: lift.symbol, tintHex: lift.tint
            )
        }

        // All-time heaviest completed set per lift.
        display.prs = TrackedLift.allCases.compactMap { lift in
            guard let pr = allSets.filter({ $0.lift == lift }).max(by: { ($0.weight, $1.date) < ($1.weight, $0.date) }) else { return nil }
            return LiftRecord(id: lift.rawValue, name: lift.title, value: "\(HubFormat.weight(pr.weight)) lbs", note: monthDay(pr.date))
        }

        if let latest = week.max(by: { $0.startedAt < $1.startedAt }) {
            display.lastWorkoutSubtitle = "\(monthDay(latest.startedAt)) • \(formatDuration(latest.durationMinutes))"
            display.lastWorkoutRows = latest.sortedExercises.compactMap { exercise in
                let done = exercise.sets.filter { $0.isCompleted }
                guard !done.isEmpty else { return nil }
                let reps = mostCommon(done.map(\.reps)) ?? 0
                let top = done.compactMap(\.weightLbs).max()
                return LiftRecord(
                    id: exercise.id.uuidString,
                    name: exercise.name,
                    value: "\(done.count) × \(reps)",
                    note: top.map { "\(HubFormat.weight($0)) lbs" } ?? "BW"
                )
            }
        } else if let latest = otherWeek.max(by: { $0.startDate < $1.startDate }) {
            display.lastWorkoutSubtitle = "\(monthDay(latest.startDate)) • \(formatDuration(latest.durationMinutes))"
            display.lastWorkoutRows = [
                LiftRecord(id: latest.id.uuidString, name: latest.type.capitalized,
                           value: "\(Int(latest.durationMinutes)) min", note: latest.notes ?? "Strength workout")
            ]
        }
        return display
    }

    static func placeholder(ending: Date = .now, dateRange: String? = nil) -> PowerliftingWeekDisplay {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: ending)
        let start = calendar.date(byAdding: .day, value: -6, to: endDay) ?? endDay
        let range = dateRange ?? "\(monthDay(start)) – \(monthDay(endDay))"
        return PowerliftingWeekDisplay(
            dateRange: range,
            stats: [
                stat("lifts", "Total Lifts", "--", "dumbbell.fill", 0x7A5AF8, ("—", "minus", false)),
                stat("volume", "Total Volume", "--", "flame.fill", 0xE1453F, ("—", "minus", false)),
                stat("time", "Total Training Time", "--", "stopwatch.fill", 0x7A5AF8, ("—", "minus", false)),
                stat("weight", "Avg. Bodyweight", "--", "scalemass.fill", 0x14B8A6, ("—", "minus", true))
            ],
            lifts: TrackedLift.allCases.map(liftSlot),
            prs: [],
            lastWorkoutSubtitle: "Log lifts in Workout Hub",
            lastWorkoutRows: [],
            placeholderMessage: "Log lifts in Workout Hub to see weekly powerlifting stats."
        )
    }

    // MARK: - Helpers

    private static func workingSets(_ sessions: [HubSession]) -> [WorkingSet] {
        sessions.flatMap { session in
            session.exercises.flatMap { exercise in
                exercise.sets.compactMap { set -> WorkingSet? in
                    guard set.isCompleted, !set.usesBodyweight, let weight = set.weightLbs, weight > 0 else { return nil }
                    return WorkingSet(lift: TrackedLift.match(exercise.name), weight: weight, reps: set.reps, date: session.startedAt)
                }
            }
        }
    }

    /// Exercises with at least one completed set.
    private static func exerciseCount(_ sessions: [HubSession]) -> Int {
        sessions.reduce(0) { total, session in
            total + session.exercises.filter { $0.sets.contains { $0.isCompleted } }.count
        }
    }

    private static func mostCommon(_ values: [Int]) -> Int? {
        Dictionary(grouping: values, by: { $0 }).max { $0.value.count < $1.value.count }?.key
    }

    private static func isStrength(_ type: String) -> Bool {
        strengthTypes.contains(type.lowercased())
    }

    private static func liftSlot(_ lift: TrackedLift) -> LiftProgress {
        LiftProgress(
            id: lift.rawValue, name: lift.title, value: "--",
            trend: "—", trendSymbol: "minus", favorable: true,
            systemImage: lift.symbol, tintHex: lift.tint
        )
    }

    private static func stat(
        _ id: String,
        _ title: String,
        _ value: String,
        _ symbol: String,
        _ tint: UInt32,
        _ trend: (String, String, Bool)
    ) -> WeeklyMetric {
        WeeklyMetric(
            id: id,
            title: title,
            value: value,
            systemImage: symbol,
            tintHex: tint,
            trend: trend.0,
            trendSymbol: trend.1,
            favorable: trend.2,
            footnote: "vs. last week"
        )
    }

    private static func delta(_ current: Double, _ previous: Double, suffix: String, digits: Int) -> (String, String, Bool) {
        guard previous > 0 || current > 0 else { return ("—", "minus", false) }
        let change = current - previous
        if abs(change) < 0.5 { return ("0\(suffix)", "minus", false) }
        let text = digits == 0
            ? String(format: "%+.0f\(suffix)", change)
            : String(format: "%+.\(digits)f\(suffix)", change)
        return (text, change > 0 ? "arrow.up" : "arrow.down", change > 0)
    }

    /// "+12%" vs last week; "New" when there was nothing last week.
    private static func percentDelta(_ current: Double, _ previous: Double) -> (String, String, Bool) {
        guard current > 0 || previous > 0 else { return ("—", "minus", false) }
        guard previous > 0 else { return ("New", "sparkles", true) }
        let change = (current - previous) / previous * 100
        if abs(change) < 0.5 { return ("0%", "minus", false) }
        return (String(format: "%+.0f%%", change), change > 0 ? "arrow.up" : "arrow.down", change > 0)
    }

    private static func formatDuration(_ minutes: Double) -> String {
        let total = max(0, Int(minutes.rounded()))
        let hours = total / 60
        let remainder = total % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }

    private static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
