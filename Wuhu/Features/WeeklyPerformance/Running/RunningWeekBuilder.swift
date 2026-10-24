import Foundation

/// What the running weekly screen renders. Mock mode uses the reference fixture.
struct RunningWeekDisplay {
    var dateRange: String
    var stats: [WeeklyMetric]
    var days: [ConsistencyDay]
    var runsCompleted: Int
    var runsPossible: Int
    var consistencyPercent: Int
    var paceSamples: [PaceHeartSample]
    var highlights: [RunningHighlight]
    var distanceNote: String?
}

enum RunningWeekBuilder {
    /// Rough walking estimate used only when the week has no workout distance.
    static let stepsPerMile = 2_000.0

    static func make(workouts: [ImportedWorkout], daily: [DailyStats], ending: Date = .now) -> RunningWeekDisplay {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: ending)
        guard let start = calendar.date(byAdding: .day, value: -6, to: end),
              let previousStart = calendar.date(byAdding: .day, value: -13, to: end) else {
            return empty(on: ending)
        }
        let previousEnd = calendar.date(byAdding: .day, value: -1, to: start) ?? start

        let currentMoves = moves(in: workouts, from: start, through: end, calendar: calendar)
        let previousMoves = moves(in: workouts, from: previousStart, through: previousEnd, calendar: calendar)
        let hasWorkoutDistance = currentMoves.contains { ($0.distanceMiles ?? 0) > 0.05 }
        let distanceNote = note(hasMoves: !currentMoves.isEmpty, hasDistance: hasWorkoutDistance)

        let days = (0..<7).map { offset -> ConsistencyDay in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let miles = miles(
                on: date,
                moves: currentMoves,
                daily: daily,
                allowEstimate: !hasWorkoutDistance,
                calendar: calendar
            )
            return ConsistencyDay(
                index: offset,
                weekday: weekdayLabel(date),
                date: monthDay(date),
                miles: miles
            )
        }

        let runDays = days.filter { ($0.miles ?? 0) > 0.05 }
        let completed = runDays.count
        let totalMiles = days.compactMap(\.miles).reduce(0, +)
        let previousMiles = previousTotal(
            moves: previousMoves,
            daily: daily,
            from: previousStart,
            through: previousEnd,
            allowEstimate: !hasWorkoutDistance,
            calendar: calendar
        )

        let paceWorkouts = currentMoves.filter { ($0.distanceMiles ?? 0) > 0.05 && $0.durationMinutes > 0 }
        let previousPaceWorkouts = previousMoves.filter { ($0.distanceMiles ?? 0) > 0.05 && $0.durationMinutes > 0 }
        let pace = averagePace(paceWorkouts)
        let previousPace = averagePace(previousPaceWorkouts)
        let heart = averageHeart(paceWorkouts)
        let previousHeart = averageHeart(previousPaceWorkouts)
        let calories = calorieTotal(currentMoves) ?? burned(daily, from: start, through: end, calendar: calendar)
        let previousCalories = calorieTotal(previousMoves) ?? burned(daily, from: previousStart, through: previousEnd, calendar: calendar)

        return RunningWeekDisplay(
            dateRange: "\(monthDay(start)) – \(monthDay(end))",
            stats: [
                metric("miles", "Total Miles", milesText(totalMiles, hasAny: completed > 0), "figure.run", 0xE15B9A, delta(totalMiles, previousMiles, suffix: " mi", digits: 1), upIsGood: true),
                metric("calories", "Calories Burned", calories.map { grouped(Int($0.rounded())) } ?? "--", "flame.fill", 0xF08A2C, percentDelta(calories, previousCalories), upIsGood: true),
                metric("pace", "Avg. Mile Time", pace.map(paceText) ?? "--", "stopwatch.fill", 0x7A5AF8, paceDelta(pace, previousPace), upIsGood: false),
                metric("hr", "Avg. Heart Rate", heart.map { "\(Int($0.rounded())) bpm" } ?? "--", "heart.fill", 0xE1453F, delta(heart, previousHeart, suffix: " bpm", digits: 0), upIsGood: false)
            ],
            days: days,
            runsCompleted: completed,
            runsPossible: 7,
            consistencyPercent: Int((Double(completed) / 7.0 * 100).rounded()),
            paceSamples: samples(from: paceWorkouts),
            highlights: highlights(from: paceWorkouts),
            distanceNote: distanceNote
        )
    }

    private static func empty(on date: Date) -> RunningWeekDisplay {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: date)
        let start = calendar.date(byAdding: .day, value: -6, to: endDay) ?? endDay
        let days = (0..<7).map { offset -> ConsistencyDay in
            let dayDate = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return ConsistencyDay(
                index: offset,
                weekday: weekdayLabel(dayDate),
                date: monthDay(dayDate),
                miles: nil
            )
        }
        return RunningWeekDisplay(
            dateRange: "\(monthDay(start)) – \(monthDay(endDay))",
            stats: [
                metric("miles", "Total Miles", "--", "figure.run", 0xE15B9A, ("—", "minus", false), upIsGood: true),
                metric("calories", "Calories Burned", "--", "flame.fill", 0xF08A2C, ("—", "minus", false), upIsGood: true),
                metric("pace", "Avg. Mile Time", "--", "stopwatch.fill", 0x7A5AF8, ("—", "minus", false), upIsGood: false),
                metric("hr", "Avg. Heart Rate", "--", "heart.fill", 0xE1453F, ("—", "minus", false), upIsGood: false)
            ],
            days: days,
            runsCompleted: 0,
            runsPossible: 7,
            consistencyPercent: 0,
            paceSamples: [],
            highlights: highlights(from: []),
            distanceNote: "No health data for this week."
        )
    }

    /// Maps pace minutes (6:00 at the top, 14:00 at the bottom) onto the heart-rate axis.
    static func paceChartY(_ minutes: Double) -> Double {
        let clamped = min(14, max(6, minutes))
        return 200 - ((clamped - 6) / 8) * 160
    }

    private static func moves(in workouts: [ImportedWorkout], from start: Date, through end: Date, calendar: Calendar) -> [ImportedWorkout] {
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return workouts.filter { workout in
            (workout.type == "running" || workout.type == "walking")
                && workout.startDate >= start
                && workout.startDate < endExclusive
        }
    }

    private static func miles(
        on date: Date,
        moves: [ImportedWorkout],
        daily: [DailyStats],
        allowEstimate: Bool,
        calendar: Calendar
    ) -> Double? {
        let workoutMiles = moves
            .filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .compactMap(\.distanceMiles)
            .reduce(0, +)
        if workoutMiles > 0.05 {
            return (workoutMiles * 10).rounded() / 10
        }
        guard allowEstimate else { return nil }
        let day = daily.first { calendar.isDate($0.date, inSameDayAs: date) }
        if let distance = day?.distanceMiles, distance > 0.05 {
            return (distance * 10).rounded() / 10
        }
        if let steps = day?.steps, steps > 0 {
            return ((Double(steps) / stepsPerMile) * 10).rounded() / 10
        }
        return nil
    }

    private static func previousTotal(
        moves: [ImportedWorkout],
        daily: [DailyStats],
        from start: Date,
        through end: Date,
        allowEstimate: Bool,
        calendar: Calendar
    ) -> Double? {
        var total = 0.0
        var any = false
        var cursor = start
        while cursor <= end {
            if let miles = miles(on: cursor, moves: moves, daily: daily, allowEstimate: allowEstimate, calendar: calendar) {
                total += miles
                any = true
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return any ? total : nil
    }

    private static func note(hasMoves: Bool, hasDistance: Bool) -> String? {
        if hasDistance { return nil }
        if hasMoves {
            return "Workouts had no distance. Miles use walking distance or a step estimate."
        }
        return "No running or walking workouts. Miles are estimated from steps when steps exist."
    }

    private static func averagePace(_ workouts: [ImportedWorkout]) -> Double? {
        let miles = workouts.compactMap(\.distanceMiles).reduce(0, +)
        let minutes = workouts.reduce(0) { $0 + $1.durationMinutes }
        guard miles > 0.05, minutes > 0 else { return nil }
        return minutes * 60 / miles
    }

    private static func averageHeart(_ workouts: [ImportedWorkout]) -> Double? {
        let samples = workouts.compactMap { workout -> (Double, Double)? in
            guard let heart = workout.averageHeartRate, workout.durationMinutes > 0 else { return nil }
            return (heart, workout.durationMinutes)
        }
        let weight = samples.reduce(0) { $0 + $1.1 }
        guard weight > 0 else { return nil }
        let total = samples.reduce(0) { $0 + $1.0 * $1.1 }
        return total / weight
    }

    private static func calorieTotal(_ workouts: [ImportedWorkout]) -> Double? {
        let values = workouts.compactMap(\.calories)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    private static func burned(_ daily: [DailyStats], from start: Date, through end: Date, calendar: Calendar) -> Double? {
        let days = daily.filter { $0.date >= start && $0.date <= end.addingTimeInterval(86_400) }
        let values = days.compactMap { day -> Double? in
            guard day.activeCalories != nil || day.restingCalories != nil else { return nil }
            return (day.activeCalories ?? 0) + (day.restingCalories ?? 0)
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    private static func samples(from workouts: [ImportedWorkout]) -> [PaceHeartSample] {
        let ordered = workouts.sorted { $0.startDate < $1.startDate }
        var cursor = 0.0
        var samples: [PaceHeartSample] = []
        for workout in ordered {
            guard let miles = workout.distanceMiles, miles > 0.05, let heart = workout.averageHeartRate else { continue }
            cursor += miles
            let paceMinutes = workout.durationMinutes / miles
            samples.append(PaceHeartSample(mile: (cursor * 10).rounded() / 10, heartRate: heart, paceMinutes: paceMinutes))
        }
        return samples
    }

    private static func highlights(from workouts: [ImportedWorkout]) -> [RunningHighlight] {
        let best = workouts.min { paceSeconds($0) < paceSeconds($1) }
        let longest = workouts.max { ($0.distanceMiles ?? 0) < ($1.distanceMiles ?? 0) }
        let peak = workouts.max { ($0.maxHeartRate ?? 0) < ($1.maxHeartRate ?? 0) }
        return [
            RunningHighlight(
                id: "best",
                title: "Best Mile Time",
                detail: "Fastest mile this week",
                value: best.flatMap { workout in
                    let seconds = paceSeconds(workout)
                    return seconds.isFinite ? paceText(seconds) : nil
                } ?? "--",
                note: best.map { "\(monthDay($0.startDate)) • \(milesText($0.distanceMiles ?? 0, hasAny: true)) run" } ?? "No pace data",
                systemImage: "trophy.fill",
                tintHex: 0xE0A106
            ),
            RunningHighlight(
                id: "long",
                title: "Longest Run",
                detail: "Farthest distance this week",
                value: longest.flatMap { $0.distanceMiles }.map { milesText($0, hasAny: true) } ?? "--",
                note: longest.map { workout in
                    let pace = paceSeconds(workout)
                    let paceLabel = pace.isFinite ? paceText(pace) : "no pace"
                    return "\(monthDay(workout.startDate)) • \(paceLabel)"
                } ?? "No distance data",
                systemImage: "flag.fill",
                tintHex: 0x3B82F6
            ),
            RunningHighlight(
                id: "peak",
                title: "Peak Heart Rate",
                detail: "Highest during a run",
                value: peak?.maxHeartRate.map { "\(Int($0.rounded())) bpm" } ?? "--",
                note: peak.map { "\(monthDay($0.startDate)) • \(milesText($0.distanceMiles ?? 0, hasAny: ($0.distanceMiles ?? 0) > 0))" } ?? "No heart-rate data",
                systemImage: "heart.fill",
                tintHex: 0xE1453F
            )
        ]
    }

    private static func paceSeconds(_ workout: ImportedWorkout) -> Double {
        guard let miles = workout.distanceMiles, miles > 0.05 else { return .greatestFiniteMagnitude }
        return workout.durationMinutes * 60 / miles
    }

    private static func metric(
        _ id: String,
        _ title: String,
        _ value: String,
        _ symbol: String,
        _ tint: UInt32,
        _ trend: (String, String, Bool),
        upIsGood: Bool
    ) -> WeeklyMetric {
        let favorable = trend.0 == "—" ? true : (upIsGood ? trend.2 : !trend.2)
        return WeeklyMetric(
            id: id,
            title: title,
            value: value,
            systemImage: symbol,
            tintHex: tint,
            trend: trend.0,
            trendSymbol: trend.1,
            favorable: favorable,
            footnote: "vs. last week"
        )
    }

    /// Returns text, symbol, and whether the current value is higher.
    private static func delta(_ current: Double?, _ previous: Double?, suffix: String, digits: Int) -> (String, String, Bool) {
        guard let current, let previous else { return ("—", "minus", false) }
        let change = current - previous
        if abs(change) < (digits == 0 ? 0.5 : 0.05) { return ("0\(suffix)", "minus", false) }
        let text = String(format: "%+.\(digits)f\(suffix)", change)
        return (text, change > 0 ? "arrow.up" : "arrow.down", change > 0)
    }

    private static func percentDelta(_ current: Double?, _ previous: Double?) -> (String, String, Bool) {
        guard let current, let previous, previous > 0 else { return ("—", "minus", false) }
        let change = (current - previous) / previous * 100
        if abs(change) < 1 { return ("0%", "minus", false) }
        return (String(format: "%+.0f%%", change), change > 0 ? "arrow.up" : "arrow.down", change > 0)
    }

    private static func paceDelta(_ current: Double?, _ previous: Double?) -> (String, String, Bool) {
        guard let current, let previous else { return ("—", "minus", false) }
        let change = Int((current - previous).rounded())
        if abs(change) < 1 { return ("0:00", "minus", false) }
        let sign = change > 0 ? "+" : "−"
        let seconds = abs(change)
        return (String(format: "%@%d:%02d", sign, seconds / 60, seconds % 60), change > 0 ? "arrow.up" : "arrow.down", change > 0)
    }

    private static func milesText(_ miles: Double, hasAny: Bool) -> String {
        guard hasAny else { return "--" }
        return String(format: "%.1f mi", miles)
    }

    private static func paceText(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d /mi", total / 60, total % 60)
    }

    private static func grouped(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    private static func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
