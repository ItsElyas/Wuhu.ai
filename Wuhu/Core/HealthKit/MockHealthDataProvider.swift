import Foundation

/// Realistic sample data for previews, simulator, and `-useMockData`.
struct MockHealthDataProvider: HealthDataProviding {
    func requestAuthorization() async throws {
        // Always succeeds in mock mode.
    }

    func fetchDailyStats(for date: Date) async throws -> DailyStats {
        let days = try await fetchDailyHistory(days: 30)
        let day = Calendar.current.startOfDay(for: date)
        if let match = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            return match
        }
        return days.last ?? DailyStats(date: day)
    }

    func fetchDailyHistory(days: Int) async throws -> [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return Self.makeDay(date: date, offsetFromToday: offset)
        }
    }

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [ImportedWorkout] {
        let calendar = Calendar.current
        let samples: [(Int, String, Double, Double, Double)] = [
            (1, "running", 35, 380, 152),
            (3, "strength", 45, 220, 128),
            (5, "cycling", 40, 310, 140),
            (8, "yoga", 30, 90, 95),
            (12, "swimming", 25, 200, 135),
        ]
        return samples.compactMap { dayOffset, type, minutes, kcal, hr in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now),
                  date >= start, date <= end else { return nil }
            return ImportedWorkout(
                id: UUID(),
                type: type,
                startDate: date,
                durationMinutes: minutes,
                calories: kcal,
                averageHeartRate: hr,
                maxHeartRate: hr + 20
            )
        }
    }

    func fetchProfile() async throws -> UserProfile {
        UserProfile(
            ageYears: 22,
            biologicalSex: "male",
            heightCm: 178,
            weightKg: 76,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -22, to: .now)
        )
    }

    private static func makeDay(date: Date, offsetFromToday: Int) -> DailyStats {
        // Deterministic-ish variation from offset.
        let wave = sin(Double(offsetFromToday) * 0.45)
        let steps = Int(8400 + wave * 1800 + Double(offsetFromToday % 5) * 120)
        let active = 410 + wave * 90
        let restingHR = 58 + wave * 3
        let hrv = 64 - wave * 8
        let sleepHours = 7.0 + wave * 0.6
        let bedtime = Calendar.current.date(bySettingHour: 23, minute: 40, second: 0, of: date)
        let wake = Calendar.current.date(bySettingHour: 7, minute: 35, second: 0, of: date)

        return DailyStats(
            date: date,
            steps: max(3200, steps),
            activeCalories: max(180, active),
            restingCalories: 1780,
            restingHeartRate: restingHR,
            latestHeartRate: offsetFromToday == 0 ? 72 : nil,
            hrvSDNN: hrv,
            sleep: SleepSummary(
                totalHours: round1(sleepHours),
                inBedHours: round1(sleepHours + 0.7),
                deepHours: round1(1.1 + wave * 0.2),
                remHours: round1(1.6 + wave * 0.15),
                coreHours: round1(4.5),
                awakeHours: 0.5,
                bedtime: bedtime,
                wakeTime: wake
            ),
            workoutMinutes: offsetFromToday % 3 == 1 ? 35 : (offsetFromToday % 5 == 0 ? 45 : 0)
        )
    }

    private static func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
