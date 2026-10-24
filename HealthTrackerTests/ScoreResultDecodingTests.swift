import Foundation
import Testing
@testable import HealthTracker

struct ScoreResultDecodingTests {
    @Test func decodesValidFixture() throws {
        let data = try fixtureData("good_week")
        var result = try JSONDecoder().decode(ScoreResult.self, from: data)
        result.clamp()
        #expect(result.insufficientData == false)
        #expect(result.vitalityAge?.years == 20.6)
        #expect(result.readiness?.score == 78)
        #expect(result.effort?.scaleMax == 21)
    }

    @Test func decodesSparseFixture() throws {
        let data = try fixtureData("sparse_data")
        let result = try JSONDecoder().decode(ScoreResult.self, from: data)
        #expect(result.insufficientData == true)
        #expect(result.vitalityAge == nil)
    }

    @Test func rejectsMalformedJSON() {
        let data = Data("{not-json".utf8)
        var failed = false
        do {
            _ = try JSONDecoder().decode(ScoreResult.self, from: data)
        } catch {
            failed = true
        }
        #expect(failed)
    }

    @Test func allowsExtraFields() throws {
        let json = """
        {"schema_version":1,"insufficient_data":false,"extra_field":true,"disclaimer":"x"}
        """
        let result = try JSONDecoder().decode(ScoreResult.self, from: Data(json.utf8))
        #expect(result.schemaVersion == 1)
    }

    @Test func clampOutOfRangeValues() {
        var result = ScoreResult(
            schemaVersion: 1,
            vitalityAge: VitalityAgeScore(years: 40, deltaVsChronological: 50, confidence: "high", drivers: nil),
            readiness: LabeledScore(score: 150, label: "great", summary: nil),
            effort: EffortScore(score: 40, scaleMax: 21, summary: nil),
            sleepScore: LabeledScore(score: -5, label: nil, summary: nil),
            method: "test",
            insufficientData: false,
            disclaimer: "x"
        )
        result.clamp()
        #expect(result.vitalityAge?.deltaVsChronological == 10)
        #expect(result.readiness?.score == 100)
        #expect(result.effort?.score == 21)
        #expect(result.sleepScore?.score == 0)
    }

    @Test func mockServiceFallsBackLocally() async throws {
        let service = MockScoringService()
        let snapshot = HealthSnapshot(
            schemaVersion: 1,
            generatedAt: "2026-10-24T10:30:00Z",
            windowDays: 30,
            profile: SnapshotProfile(ageYears: 22, biologicalSex: "male", heightCm: 178, weightKg: 76),
            today: SnapshotToday(steps: 6000, activeKcal: 400, basalKcal: 1700, restingHrBpm: 58, latestHrBpm: 70, hrvSdnnMs: 60, sleep: nil, workouts: []),
            dailyHistory: (0..<14).map { SnapshotDay(date: "2026-10-\($0 + 1)", steps: 8000, activeKcal: 400, restingHrBpm: 58, hrvSdnnMs: 60, sleepHours: 7, workoutMinutes: 20) },
            bodyStatus: [],
            baselines: SnapshotBaselines(restingHrBpm30dAvg: 58, hrvSdnnMs30dAvg: 60, sleepHours30dAvg: 7, steps30dAvg: 8000, sleepConsistencyStddevMin: 30),
            dataQuality: SnapshotDataQuality(daysWithData: 14, missingMetrics: [])
        )
        let result = try await service.score(snapshot: snapshot)
        #expect(result.insufficientData == false)
        #expect(result.vitalityAge?.years != nil)
    }

    private func fixtureData(_ name: String) throws -> Data {
        let url = Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
            ?? Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json")
            ?? URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Fixtures/\(name).json")
        return try Data(contentsOf: url)
    }
}

private final class BundleToken: NSObject {}
