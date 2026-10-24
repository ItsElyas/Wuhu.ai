import Foundation
import Testing
@testable import HealthTracker

struct HealthSnapshotBuilderTests {
    let builder = HealthSnapshotBuilder()

    @Test func buildsRoundedSnapshotAndOmitsHealthyBodyNotes() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var history: [DailyStats] = []
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            history.append(
                DailyStats(
                    date: date,
                    steps: 6120 + i,
                    activeCalories: 410.4,
                    restingCalories: 1780.2,
                    restingHeartRate: 58.4,
                    hrvSDNN: 64.44,
                    sleep: SleepSummary(totalHours: 7.21, deepHours: 1.14),
                    workoutMinutes: 35.6
                )
            )
        }
        history.reverse()

        let injured = BodyPartStatusRecord(
            part: .rightKnee,
            status: .injured,
            severity: 2,
            note: "secret personal note"
        )
        let healthy = BodyPartStatusRecord(part: .chest, status: .healthy)

        let snapshot = builder.build(
            history: history,
            todayWorkouts: [
                ImportedWorkout(
                    id: UUID(),
                    type: "running",
                    startDate: .now,
                    durationMinutes: 35.2,
                    calories: 380.7,
                    averageHeartRate: 152.2,
                    maxHeartRate: 176.8
                ),
            ],
            profile: UserProfile(ageYears: 22, biologicalSex: "male", heightCm: 178.4, weightKg: 76.2),
            bodyStatuses: [injured, healthy]
        )

        #expect(snapshot.schemaVersion == 1)
        #expect(snapshot.dailyHistory.count == 10)
        #expect(snapshot.today.steps == 6120)
        #expect(snapshot.today.activeKcal == 410)
        #expect(snapshot.bodyStatus.count == 1)
        #expect(snapshot.bodyStatus.first?.part == "rightKnee")
        #expect(snapshot.bodyStatus.first?.status == "injured")

        let json = try builder.jsonString(from: snapshot)
        #expect(!json.contains("secret personal note"))
        #expect(json.contains("rightKnee"))
    }

    @Test func capsHistoryAtThirtyDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let history = (0..<40).map { i -> DailyStats in
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            return DailyStats(date: date, steps: 1000 + i)
        }.reversed()

        let snapshot = builder.build(
            history: Array(history),
            todayWorkouts: [],
            profile: UserProfile(ageYears: 30),
            bodyStatuses: [],
            windowDays: 30
        )
        #expect(snapshot.dailyHistory.count == 30)
    }
}
