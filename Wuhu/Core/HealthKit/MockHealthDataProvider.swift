import Foundation

/// Sample Health data used by demo mode (Settings → Demo mode), SwiftUI previews, and tests.
/// Deterministic per day so the demo looks the same every time.
struct MockHealthDataProvider: HealthDataProviding {
    func requestAuthorization() async throws {
        // Always succeeds in demo mode.
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

    /// Health-app style workouts (runs include distance so pace and weekly running fill in).
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [ImportedWorkout] {
        let calendar = Calendar.current
        // (days ago, hour, type, minutes, kcal, avg HR, miles)
        let samples: [(Int, Int, String, Double, Double, Double, Double?)] = [
            (0, 7, "running", 26.5, 330, 154, 3.2),
            (2, 18, "running", 34, 410, 149, 4.0),
            (4, 7, "running", 41.5, 520, 156, 5.1),
            (6, 17, "cycling", 40, 310, 140, nil),
            (7, 8, "running", 30, 360, 151, 3.6),
            (9, 7, "running", 58, 690, 147, 6.8),
            (11, 18, "yoga", 30, 90, 95, nil),
            (13, 7, "running", 28, 340, 153, 3.4),
            (16, 7, "running", 45, 540, 150, 5.4),
            (20, 18, "swimming", 25, 200, 135, nil),
        ]
        return samples.compactMap { daysAgo, hour, type, minutes, kcal, hr, miles in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now)),
                  let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                  date >= start, date <= end, date <= .now else { return nil }
            return ImportedWorkout(
                id: UUID(),
                type: type,
                startDate: date,
                durationMinutes: minutes,
                calories: kcal,
                averageHeartRate: hr,
                maxHeartRate: hr + 20,
                distanceMiles: miles
            )
        }
    }

    func fetchProfile() async throws -> UserProfile {
        UserProfile(
            ageYears: 22,
            biologicalSex: "male",
            heightCm: 178,
            weightKg: 76,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -22, to: .now),
            displayName: "Alex"
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
        let intake = 2_350 + wave * 220

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
            workoutMinutes: offsetFromToday % 3 == 1 ? 35 : (offsetFromToday % 5 == 0 ? 45 : 0),
            intakeCalories: intake.rounded(),
            proteinGrams: (150 + wave * 15).rounded(),
            carbGrams: (260 + wave * 30).rounded(),
            fatGrams: (78 + wave * 8).rounded(),
            distanceMiles: round1(Double(max(3200, steps)) / 2_100)
        )
    }

    private static func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
