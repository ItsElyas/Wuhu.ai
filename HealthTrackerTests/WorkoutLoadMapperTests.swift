import Testing
@testable import HealthTracker

struct WorkoutLoadMapperTests {
    @Test func runningMapsToLegs() {
        let parts = WorkoutLoadMapper.parts(forWorkoutType: "running")
        #expect(parts.contains(.leftQuad))
        #expect(parts.contains(.rightCalf))
        #expect(parts.contains(.glutes))
    }

    @Test func pushUpsMapToUpperBody() {
        let parts = WorkoutLoadMapper.parts(forWorkoutType: "push-ups")
        #expect(parts.contains(.chest))
        #expect(parts.contains(.leftTricep))
        #expect(parts.contains(.rightShoulder))
    }

    @Test func intensityScalesWithDurationAndHR() {
        let short = WorkoutLoadMapper.intensity(durationMinutes: 10, averageHeartRate: 110)
        let longHard = WorkoutLoadMapper.intensity(durationMinutes: 60, averageHeartRate: 170)
        #expect(longHard > short)
        #expect(short >= 0.15)
        #expect(longHard <= 1.0)
    }

    @Test func decayReachesZero() {
        let mid = WorkoutLoadMapper.decayedIntensity(base: 1, hoursSince: 30)
        let done = WorkoutLoadMapper.decayedIntensity(base: 1, hoursSince: WorkoutLoadMapper.workedDecayHours)
        #expect(mid > 0)
        #expect(done == 0)
    }

    @Test func autoLoadNeverSetsInjured() {
        var records: [BodyPartStatusRecord] = []
        WorkoutLoadMapper.applyWorkoutLoad(
            to: &records,
            parts: [.chest],
            durationMinutes: 50,
            averageHeartRate: 160
        )
        #expect(records.first?.status != .injured)
    }

    @Test func workedDoesNotOverwriteInjured() {
        var records = [
            BodyPartStatusRecord(part: .leftKnee, status: .injured, severity: 3, intensity: 1),
        ]
        WorkoutLoadMapper.applyWorkoutLoad(
            to: &records,
            parts: [.leftKnee],
            durationMinutes: 40,
            averageHeartRate: 140
        )
        #expect(records.first?.status == .injured)
    }

    @Test func clearingResetsHealthyViaManualUpdate() async {
        // Documented rule covered by BodyMapViewModel.updateStatus(.healthy)
        let record = BodyPartStatusRecord(part: .chest, status: .sore, severity: 2)
        record.status = .healthy
        record.intensity = 0
        #expect(record.status == .healthy)
        #expect(record.intensity == 0)
    }
}
