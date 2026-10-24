import Testing
@testable import Wuhu

struct WeeklyStatsTests {
    @Test func weekOverWeekPercent() {
        let change = WeeklyStats.weekOverWeekChange(current: 110, previous: 100)
        #expect(change == 10)
        #expect(WeeklyStats.weekOverWeekChange(current: 50, previous: 0) == nil)
    }

    @Test func averageIgnoresEmpty() {
        #expect(WeeklyStats.average(of: []) == nil)
        #expect(WeeklyStats.average(of: [2, 4, 6]) == 4)
    }

    @Test func workoutDedupByStartAndType() {
        let a = WorkoutRecord(type: "running", startDate: Date(timeIntervalSince1970: 1_000), durationMinutes: 30, source: .healthKit)
        let b = WorkoutRecord(type: "running", startDate: Date(timeIntervalSince1970: 1_030), durationMinutes: 30, source: .manual)
        let c = WorkoutRecord(type: "cycling", startDate: Date(timeIntervalSince1970: 1_000), durationMinutes: 40, source: .manual)
        let merged = WorkoutRecord.mergeDeduplicating([a, b, c])
        #expect(merged.count == 2)
    }
}
