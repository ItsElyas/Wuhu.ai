import Foundation

/// Builds a compact `HealthSnapshot` from on-device aggregates. Never invents values.
struct HealthSnapshotBuilder: Sendable {
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func build(
        history: [DailyStats],
        todayWorkouts: [ImportedWorkout],
        profile: UserProfile,
        bodyStatuses: [BodyPartStatusRecord],
        windowDays: Int = 30,
        now: Date = .now
    ) -> HealthSnapshot {
        let capped = Array(history.suffix(windowDays))
        let todayDay = Calendar.current.startOfDay(for: now)
        let todayStats = capped.last(where: { Calendar.current.isDate($0.date, inSameDayAs: todayDay) })
            ?? capped.last

        let historyRows: [SnapshotDay] = capped.map { day in
            SnapshotDay(
                date: dayFormatter.string(from: day.date),
                steps: day.steps,
                activeKcal: day.activeCalories.map(round0),
                restingHrBpm: day.restingHeartRate.map(round0),
                hrvSdnnMs: day.hrvSDNN.map(round1),
                sleepHours: day.sleep.map { round1($0.totalHours) },
                workoutMinutes: day.workoutMinutes.map(round0)
            )
        }

        let daysWithData = capped.filter { dayHasUsefulData($0) }.count
        var missing: [String] = []
        if todayStats?.hrvSDNN == nil { missing.append("hrv_sdnn_ms") }
        if todayStats?.restingHeartRate == nil { missing.append("resting_hr_bpm") }
        if todayStats?.sleep == nil { missing.append("sleep") }

        let sleepHours = capped.compactMap { $0.sleep?.totalHours }
        let bedMinutes = capped.compactMap { day -> Double? in
            guard let bed = day.sleep?.bedtime else { return nil }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: bed)
            return Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
        }

        return HealthSnapshot(
            schemaVersion: 1,
            generatedAt: isoFormatter.string(from: now),
            windowDays: windowDays,
            profile: SnapshotProfile(
                ageYears: profile.ageYears,
                biologicalSex: profile.biologicalSex,
                heightCm: profile.heightCm.map(round0),
                weightKg: profile.weightKg.map(round1)
            ),
            today: SnapshotToday(
                steps: todayStats?.steps,
                activeKcal: todayStats?.activeCalories.map(round0),
                basalKcal: todayStats?.restingCalories.map(round0),
                restingHrBpm: todayStats?.restingHeartRate.map(round0),
                latestHrBpm: todayStats?.latestHeartRate.map(round0),
                hrvSdnnMs: todayStats?.hrvSDNN.map(round1),
                sleep: todayStats?.sleep.map { sleep in
                    SnapshotSleep(
                        totalHours: round1(sleep.totalHours),
                        inBedHours: sleep.inBedHours.map(round1),
                        deepHours: sleep.deepHours.map(round1),
                        remHours: sleep.remHours.map(round1),
                        coreHours: sleep.coreHours.map(round1),
                        awakeHours: sleep.awakeHours.map(round1),
                        bedtime: sleep.bedtime.map { timeFormatter.string(from: $0) },
                        wakeTime: sleep.wakeTime.map { timeFormatter.string(from: $0) }
                    )
                },
                workouts: todayWorkouts.map {
                    SnapshotWorkout(
                        type: $0.type,
                        minutes: round0($0.durationMinutes),
                        kcal: $0.calories.map(round0),
                        avgHrBpm: $0.averageHeartRate.map(round0),
                        maxHrBpm: $0.maxHeartRate.map(round0)
                    )
                }
            ),
            dailyHistory: historyRows,
            bodyStatus: bodyStatuses.compactMap(snapshotBodyStatus),
            baselines: SnapshotBaselines(
                restingHrBpm30dAvg: average(capped.compactMap(\.restingHeartRate)).map(round0),
                hrvSdnnMs30dAvg: average(capped.compactMap(\.hrvSDNN)).map(round1),
                sleepHours30dAvg: average(sleepHours).map(round1),
                steps30dAvg: average(capped.compactMap { $0.steps.map(Double.init) }).map(round0),
                sleepConsistencyStddevMin: stddev(bedMinutes).map(round0)
            ),
            dataQuality: SnapshotDataQuality(
                daysWithData: daysWithData,
                missingMetrics: missing
            )
        )
    }

    func jsonString(from snapshot: HealthSnapshot) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HealthDataError.queryFailed("Could not encode snapshot JSON.")
        }
        return string
    }

    func hash(of snapshot: HealthSnapshot) throws -> String {
        let string = try jsonString(from: snapshot)
        return String(string.hashValue)
    }

    private func snapshotBodyStatus(_ record: BodyPartStatusRecord) -> SnapshotBodyStatus? {
        guard record.status != .healthy else { return nil }
        // Omit free-text notes — may contain personal details.
        switch record.status {
        case .injured, .sore:
            return SnapshotBodyStatus(
                part: record.part.rawValue,
                status: record.status.rawValue,
                severity: record.severity,
                intensity: nil,
                daysSinceStart: record.daysSinceStart,
                hoursSinceLastLoad: nil
            )
        case .worked:
            return SnapshotBodyStatus(
                part: record.part.rawValue,
                status: record.status.rawValue,
                severity: nil,
                intensity: round1(record.intensity),
                daysSinceStart: nil,
                hoursSinceLastLoad: round0(record.hoursSinceUpdate)
            )
        case .healthy:
            return nil
        }
    }

    private func dayHasUsefulData(_ day: DailyStats) -> Bool {
        day.steps != nil
            || day.activeCalories != nil
            || day.restingHeartRate != nil
            || day.sleep != nil
            || day.workoutMinutes != nil
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func stddev(_ values: [Double]) -> Double? {
        guard values.count >= 2, let mean = average(values) else { return nil }
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }

    private func round0(_ value: Double) -> Double { value.rounded() }
    private func round1(_ value: Double) -> Double { (value * 10).rounded() / 10 }
}
