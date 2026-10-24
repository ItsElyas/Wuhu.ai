import Testing
@testable import HealthTracker

struct VitalityAgeCalculatorTests {
    let calculator = VitalityAgeCalculator()

    @Test func insufficientDataReturnsNilAge() {
        let output = calculator.calculate(
            .init(
                chronologicalAge: 30,
                daysWithData: 3,
                avgRestingHR: 55,
                avgSleepHours: 8,
                sleepConsistencyStddevMinutes: 20,
                avgSteps: 10_000,
                avgWorkoutMinutes: 40,
                avgHRV: 70
            )
        )
        #expect(output.insufficientData == true)
        #expect(output.vitalityAgeYears == nil)
    }

    @Test func betterStatsNeverRaiseAge() {
        let worse = calculator.calculate(
            .init(
                chronologicalAge: 30,
                daysWithData: 14,
                avgRestingHR: 75,
                avgSleepHours: 5.5,
                sleepConsistencyStddevMinutes: 80,
                avgSteps: 3_000,
                avgWorkoutMinutes: 5,
                avgHRV: 30
            )
        )
        let better = calculator.calculate(
            .init(
                chronologicalAge: 30,
                daysWithData: 14,
                avgRestingHR: 52,
                avgSleepHours: 7.8,
                sleepConsistencyStddevMinutes: 15,
                avgSteps: 11_000,
                avgWorkoutMinutes: 45,
                avgHRV: 75
            )
        )
        #expect(better.vitalityAgeYears != nil)
        #expect(worse.vitalityAgeYears != nil)
        #expect(better.vitalityAgeYears! <= worse.vitalityAgeYears!)
    }

    @Test func deltaIsClamped() {
        let extreme = calculator.calculate(
            .init(
                chronologicalAge: 25,
                daysWithData: 30,
                avgRestingHR: 40,
                avgSleepHours: 8,
                sleepConsistencyStddevMinutes: 5,
                avgSteps: 20_000,
                avgWorkoutMinutes: 90,
                avgHRV: 120
            )
        )
        #expect(abs(extreme.deltaYears ?? 99) <= VitalityConfig.maxAgeOffset)
    }

    @Test func missingMetricsStillScoresAvailableOnes() {
        let output = calculator.calculate(
            .init(
                chronologicalAge: 40,
                daysWithData: 10,
                avgRestingHR: 60,
                avgSleepHours: nil,
                sleepConsistencyStddevMinutes: nil,
                avgSteps: 8_000,
                avgWorkoutMinutes: nil,
                avgHRV: nil
            )
        )
        #expect(output.insufficientData == false)
        #expect(output.vitalityAgeYears != nil)
        #expect(output.metricScores["resting_hr"] != nil)
        #expect(output.metricScores["sleep_duration"] == nil)
    }

    @Test func scoreResultClampRanges() {
        var result = calculator.scoreResult(
            from: .init(
                chronologicalAge: 22,
                daysWithData: 20,
                avgRestingHR: 58,
                avgSleepHours: 7.2,
                sleepConsistencyStddevMinutes: 40,
                avgSteps: 8_400,
                avgWorkoutMinutes: 25,
                avgHRV: 60
            )
        )
        result.clamp()
        #expect((result.readiness?.score ?? -1) >= 0)
        #expect((result.readiness?.score ?? 999) <= 100)
        #expect((result.effort?.score ?? -1) >= 0)
        #expect((result.effort?.score ?? 999) <= 21)
    }
}
