import Foundation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let settings: AppSettings
    var healthProvider: any HealthDataProviding
    var scoringService: any ScoringService
    var chatService: any ChatService

    var dailyHistory: [DailyStats] = []
    var today: DailyStats?
    var weekly: WeeklyStats?
    var profile: UserProfile = UserProfile()
    var latestScores: ScoreResult?
    var usedLocalFallback = false
    var isLoading = false
    var errorMessage: String?
    var lastSnapshot: HealthSnapshot?

    private let snapshotBuilder = HealthSnapshotBuilder()
    private let localCalculator = VitalityAgeCalculator()

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        self.healthProvider = settings.useMockData
            ? MockHealthDataProvider()
            : HealthKitManager()
        self.scoringService = ScoringServiceFactory.make(
            useMock: settings.useMockData,
            aiEnabled: settings.aiScoringConsent
        )
        self.chatService = Self.makeChat(settings: settings)
    }

    func refreshProvider() {
        healthProvider = settings.useMockData ? MockHealthDataProvider() : HealthKitManager()
        scoringService = ScoringServiceFactory.make(
            useMock: settings.useMockData,
            aiEnabled: settings.aiScoringConsent
        )
        chatService = Self.makeChat(settings: settings)
    }

    func bootstrap(modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if !settings.useMockData {
                try await healthProvider.requestAuthorization()
            } else {
                try await healthProvider.requestAuthorization()
            }
            try await reloadAll(modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            // Fall back to mock so the UI still works.
            if !settings.useMockData {
                settings.useMockData = true
                refreshProvider()
                try? await reloadAll(modelContext: modelContext)
            }
        }
    }

    func reloadAll(modelContext: ModelContext) async throws {
        var history = try await healthProvider.fetchDailyHistory(days: 30)
        var fetchedProfile = try await healthProvider.fetchProfile()
        if fetchedProfile.ageYears == nil {
            fetchedProfile.ageYears = settings.chronologicalAge
        }
        if fetchedProfile.biologicalSex == nil {
            fetchedProfile.biologicalSex = settings.biologicalSex
        }
        if fetchedProfile.heightCm == nil {
            fetchedProfile.heightCm = settings.heightCm
        }
        if fetchedProfile.weightKg == nil {
            fetchedProfile.weightKg = settings.weightKg
        }
        profile = fetchedProfile
        dailyHistory = history
        today = history.last
        weekly = Self.buildWeekly(from: history)

        let start = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let imported = try await healthProvider.fetchWorkouts(from: start, to: .now)
        try Self.mergeImportedWorkouts(imported, into: modelContext)

        var bodyRecords = try modelContext.fetch(FetchDescriptor<BodyPartStatusRecord>())
        WorkoutLoadMapper.applyDecay(to: &bodyRecords)
        try modelContext.save()

        let todayStart = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart) ?? .now
        let todayImported = imported.filter { $0.startDate >= todayStart && $0.startDate < tomorrow }

        let snapshot = snapshotBuilder.build(
            history: history,
            todayWorkouts: todayImported,
            profile: profile,
            bodyStatuses: bodyRecords
        )
        lastSnapshot = snapshot
        if let json = try? snapshotBuilder.jsonString(from: snapshot) {
            settings.lastSnapshotJSON = json
        }

        try await refreshScores(snapshot: snapshot, modelContext: modelContext)
    }

    func refreshScores(snapshot: HealthSnapshot, modelContext: ModelContext) async throws {
        let dayKey = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: .now))
        let hash = (try? snapshotBuilder.hash(of: snapshot)) ?? UUID().uuidString

        let descriptor = FetchDescriptor<CachedScoreResult>(
            predicate: #Predicate { $0.dayKey == dayKey && $0.snapshotHash == hash }
        )
        if let cached = try modelContext.fetch(descriptor).first,
           let decoded = try? JSONDecoder().decode(ScoreResult.self, from: cached.jsonData) {
            latestScores = decoded
            usedLocalFallback = cached.usedLocalFallback
            settings.lastScoreJSON = String(data: cached.jsonData, encoding: .utf8) ?? ""
            return
        }

        usedLocalFallback = false
        do {
            var result = try await scoringService.score(snapshot: snapshot)
            result.clamp()
            latestScores = result
            let data = try JSONEncoder().encode(result)
            settings.lastScoreJSON = String(data: data, encoding: .utf8) ?? ""
            modelContext.insert(
                CachedScoreResult(
                    snapshotHash: hash,
                    dayKey: dayKey,
                    jsonData: data,
                    usedLocalFallback: false
                )
            )
            try modelContext.save()
        } catch {
            let input = VitalityAgeCalculator.Input(
                chronologicalAge: snapshot.profile.ageYears ?? settings.chronologicalAge,
                daysWithData: snapshot.dataQuality.daysWithData,
                avgRestingHR: snapshot.baselines.restingHrBpm30dAvg,
                avgSleepHours: snapshot.baselines.sleepHours30dAvg,
                sleepConsistencyStddevMinutes: snapshot.baselines.sleepConsistencyStddevMin,
                avgSteps: snapshot.baselines.steps30dAvg,
                avgWorkoutMinutes: average(snapshot.dailyHistory.compactMap(\.workoutMinutes)),
                avgHRV: snapshot.baselines.hrvSdnnMs30dAvg
            )
            let fallback = localCalculator.scoreResult(from: input)
            latestScores = fallback
            usedLocalFallback = true
            let data = try JSONEncoder().encode(fallback)
            settings.lastScoreJSON = String(data: data, encoding: .utf8) ?? ""
            modelContext.insert(
                CachedScoreResult(
                    snapshotHash: hash,
                    dayKey: dayKey,
                    jsonData: data,
                    usedLocalFallback: true
                )
            )
            try modelContext.save()
        }
    }

    static func buildWeekly(from history: [DailyStats]) -> WeeklyStats {
        let last7 = Array(history.suffix(7))
        let prev7 = Array(history.suffix(14).prefix(7))
        let avgSteps = WeeklyStats.average(of: last7.compactMap { $0.steps.map(Double.init) })
        let prevSteps = WeeklyStats.average(of: prev7.compactMap { $0.steps.map(Double.init) })
        let avgActive = WeeklyStats.average(of: last7.compactMap(\.activeCalories))
        let prevActive = WeeklyStats.average(of: prev7.compactMap(\.activeCalories))
        let avgRHR = WeeklyStats.average(of: last7.compactMap(\.restingHeartRate))
        let prevRHR = WeeklyStats.average(of: prev7.compactMap(\.restingHeartRate))
        let avgSleep = WeeklyStats.average(of: last7.compactMap { $0.sleep?.totalHours })
        let prevSleep = WeeklyStats.average(of: prev7.compactMap { $0.sleep?.totalHours })
        return WeeklyStats(
            days: last7,
            averageSteps: avgSteps,
            averageActiveCalories: avgActive,
            averageRestingHeartRate: avgRHR,
            averageSleepHours: avgSleep,
            averageWorkoutMinutes: WeeklyStats.average(of: last7.compactMap(\.workoutMinutes)),
            stepsChangePercent: WeeklyStats.weekOverWeekChange(current: avgSteps, previous: prevSteps),
            activeCaloriesChangePercent: WeeklyStats.weekOverWeekChange(current: avgActive, previous: prevActive),
            restingHeartRateChangePercent: WeeklyStats.weekOverWeekChange(current: avgRHR, previous: prevRHR),
            sleepChangePercent: WeeklyStats.weekOverWeekChange(current: avgSleep, previous: prevSleep)
        )
    }

    static func mergeImportedWorkouts(_ imported: [ImportedWorkout], into context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<WorkoutRecord>())
        for item in imported {
            let candidate = WorkoutRecord(
                id: item.id,
                type: item.type,
                startDate: item.startDate,
                durationMinutes: item.durationMinutes,
                calories: item.calories,
                averageHeartRate: item.averageHeartRate,
                maxHeartRate: item.maxHeartRate,
                intensity: .moderate,
                notes: nil,
                source: .healthKit,
                musclesWorked: WorkoutLoadMapper.parts(forWorkoutType: item.type)
            )
            if existing.contains(where: { WorkoutRecord.isDuplicate($0, candidate) }) {
                continue
            }
            context.insert(candidate)
        }
        try context.save()
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func makeChat(settings: AppSettings) -> any ChatService {
        if settings.useMockData || !settings.aiScoringConsent {
            return MockChatService()
        }
        let key = Bundle.main.object(forInfoDictionaryKey: "LLM_API_KEY") as? String ?? ""
        let base = Bundle.main.object(forInfoDictionaryKey: "LLM_BASE_URL") as? String ?? "https://api.openai.com/v1"
        let model = Bundle.main.object(forInfoDictionaryKey: "LLM_MODEL") as? String ?? "gpt-4o-mini"
        let cleaned = base.replacingOccurrences(of: "\\/", with: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: cleaned), !key.isEmpty, key != "your_api_key_here" else {
            return MockChatService()
        }
        return LLMChatService(apiKey: key, baseURL: url, model: model)
    }
}
