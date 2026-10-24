import Foundation
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let settings: AppSettings
    var healthProvider: any HealthDataProviding
    var scoringService: any ScoringService
    var chatService: any ChatService
    var chatOrchestrator: ChatOrchestrator

    var dailyHistory: [DailyStats] = []
    var today: DailyStats?
    var weekly: WeeklyStats?
    var profile: UserProfile = UserProfile()
    var latestScores: ScoreResult?
    var usedLocalFallback = false
    var isLoading = false
    var errorMessage: String?
    var lastSnapshot: HealthSnapshot?
    /// Workouts from the last 30 days. Weekly running uses the last 7.
    var recentWorkouts: [ImportedWorkout] = []
    /// Today's intake, cached until the next reload or pull to refresh.
    var nutrition: NutritionSummary?
    var nutritionMessage: String = "Not connected"
    /// Bumps after each successful reload so Home can refresh when mock toggles without `today` changing.
    var reloadGeneration: Int = 0
    var lastReloadFinishedAt: Date?
    /// Derived wear levels for Home mini figure and Body Map daily view (refreshed on reload).
    var wearTearResult: WearTearResult?
    let profilePreferences = ProfilePreferences()
    var playerProfileStore = PlayerProfileStore()
    /// Full-screen workout logger visibility. Owned at the root so the Home bubble,
    /// Workout Hub, and Live Activity taps all open the same logger.
    var isWorkoutLoggerPresented = false
    /// WSL estimated from available data when the profile has no explicit evaluation (see `refreshWSL`).
    var autoWSL: WSLAutoEvaluator.Result?
    let workoutDatabaseEngine = WorkoutDatabaseEngine()

    var homeDataSourceLabel: HomeDataSourceLabel {
        if isLoading { return .loading }
        if settings.demoMode { return .demo }
        if errorMessage != nil { return .error }
        if let today, HealthAccessCopy.hasAnyMetric(on: today) { return .health }
        if dailyHistory.contains(where: HealthAccessCopy.hasAnyMetric(on:)) { return .health }
        return .healthEmpty
    }

    /// Shown when live mode loaded but today has no readable samples.
    var healthAccessHint: String? {
        guard !isLoading else { return nil }
        if errorMessage != nil { return nil }
        guard homeDataSourceLabel == .healthEmpty else { return nil }
        return HealthAccessCopy.openHealthSettings
    }

    private let snapshotBuilder = HealthSnapshotBuilder()
    private let localCalculator = VitalityAgeCalculator()
    private let myNetDiary: any MyNetDiaryProviding = MyNetDiaryAPIService()

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        self.healthProvider = Self.makeHealthProvider(settings: settings)
        self.scoringService = ScoringServiceFactory.make(aiEnabled: settings.aiScoringConsent)
        self.chatService = Self.makeChat(settings: settings)
        self.chatOrchestrator = ChatOrchestrator.make(settings: settings)
        syncWeeklyPerformanceFromProfile()
    }

    func syncWeeklyPerformanceFromProfile() {
        profilePreferences.weeklyPerformanceMode = playerProfileStore.weeklyPerformanceMode
    }

    /// Demo mode reads sample data; otherwise Apple Health.
    static func makeHealthProvider(settings: AppSettings) -> any HealthDataProviding {
        settings.demoMode ? MockHealthDataProvider() : HealthKitManager()
    }

    /// Clears everything loaded from the previous data source (used when demo mode toggles).
    func resetLoadedState() {
        dailyHistory = []
        today = nil
        weekly = nil
        profile = UserProfile()
        latestScores = nil
        usedLocalFallback = false
        errorMessage = nil
        lastSnapshot = nil
        recentWorkouts = []
        nutrition = nil
        nutritionMessage = "Not connected"
        wearTearResult = nil
        autoWSL = nil
        isWorkoutLoggerPresented = false
        reloadGeneration += 1
    }

    func refreshProvider() {
        healthProvider = Self.makeHealthProvider(settings: settings)
        scoringService = ScoringServiceFactory.make(aiEnabled: settings.aiScoringConsent)
        chatService = Self.makeChat(settings: settings)
        chatOrchestrator = ChatOrchestrator.make(settings: settings)
    }

    /// Settings "Test connection" — minimal Gemini ping, updates `GeminiChatDiagnostics`.
    func probeGeminiChatConnection() async {
        let result = await GeminiConfiguration.probeConnection()
        switch result {
        case .success:
            GeminiChatDiagnostics.recordSuccess()
        case let .failure(error):
            GeminiChatDiagnostics.recordFailure(error.errorDescription ?? "Gemini probe failed.")
        }
    }

    func reloadReportingErrors(modelContext: ModelContext) async {
        do {
            try await reloadAll(modelContext: modelContext)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bootstrap(modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await reloadAll(modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadAll(modelContext: ModelContext) async throws {
        do {
            try await healthProvider.requestAuthorization()
        } catch {
            dailyHistory = []
            today = nil
            weekly = nil
            recentWorkouts = []
            nutrition = nil
            nutritionMessage = "Health access is unavailable."
            throw error
        }
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
        let calendar = Calendar.current
        today = history.last(where: { calendar.isDateInToday($0.date) }) ?? history.last
        weekly = Self.buildWeekly(from: history)

        let start = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let imported = (try? await healthProvider.fetchWorkouts(from: start, to: .now)) ?? []
        recentWorkouts = imported
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

        let workoutRecords = try modelContext.fetch(FetchDescriptor<WorkoutRecord>())
        refreshWear(bodyRecords: bodyRecords, workoutRecords: workoutRecords)
        refreshWSL(modelContext: modelContext)

        try await refreshScores(snapshot: snapshot, modelContext: modelContext)
        await refreshNutrition()
        reloadGeneration += 1
        lastReloadFinishedAt = .now
    }

    /// Recomputes wear from HealthKit imports, Workout Hub logs, body status, and last night's sleep.
    func refreshWear(bodyRecords: [BodyPartStatusRecord], workoutRecords: [WorkoutRecord]) {
        let events = Self.wearWorkoutEvents(imported: recentWorkouts, logged: workoutRecords)
        wearTearResult = WearTearEngine.compute(
            WearTearInput(
                bodyRecords: bodyRecords,
                workouts: events,
                sleepHoursLastNight: today?.sleep?.totalHours
            )
        )
    }

    func refreshWear(modelContext: ModelContext, bodyRecords: [BodyPartStatusRecord]) {
        let workouts = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        refreshWear(bodyRecords: bodyRecords, workoutRecords: workouts)
    }

    static func wearWorkoutEvents(imported: [ImportedWorkout], logged: [WorkoutRecord]) -> [WearWorkoutEvent] {
        var events: [WearWorkoutEvent] = imported.map { item in
            WearWorkoutEvent(
                startDate: item.startDate,
                type: item.type,
                durationMinutes: item.durationMinutes,
                averageHeartRate: item.averageHeartRate,
                musclesWorked: WorkoutLoadMapper.parts(forWorkoutType: item.type)
            )
        }
        for record in logged {
            let candidate = WearWorkoutEvent(
                startDate: record.startDate,
                type: record.type,
                durationMinutes: record.durationMinutes,
                averageHeartRate: record.averageHeartRate,
                musclesWorked: record.musclesWorked
            )
            let duplicate = events.contains { Self.isDuplicateWearEvent($0, candidate) }
            if duplicate { continue }
            events.append(candidate)
        }
        return events
    }

    private static func isDuplicateWearEvent(_ a: WearWorkoutEvent, _ b: WearWorkoutEvent, toleranceSeconds: TimeInterval = 60) -> Bool {
        a.type.localizedCaseInsensitiveCompare(b.type) == .orderedSame
            && abs(a.startDate.timeIntervalSince(b.startDate)) <= toleranceSeconds
    }

    /// Prefers the MyNetDiary diary call when a key is set, then Apple Health dietary energy.
    func refreshNutrition() async {
        if !settings.demoMode, MyNetDiaryConfiguration.isConfigured {
            do {
                nutrition = try await myNetDiary.fetchSummary(days: 7)
                nutritionMessage = "Connected"
                return
            } catch {
                nutritionMessage = "MyNetDiary request failed. Showing Apple Health intake when it exists."
            }
        }
        let todayIn = today?.intakeCalories.map { Int($0.rounded()) }
        let weekValues = dailyHistory.suffix(7).compactMap(\.intakeCalories)
        let weekIn = weekValues.isEmpty ? nil : Int(weekValues.reduce(0, +).rounded())
        if todayIn != nil || weekIn != nil {
            nutrition = NutritionSummary(
                todayCaloriesIn: todayIn,
                weekCaloriesIn: weekIn,
                proteinGrams: today?.proteinGrams.map { Int($0.rounded()) },
                carbGrams: today?.carbGrams.map { Int($0.rounded()) },
                fatGrams: today?.fatGrams.map { Int($0.rounded()) },
                source: .appleHealth
            )
            if settings.demoMode {
                nutritionMessage = "Demo data"
            } else if !MyNetDiaryConfiguration.isConfigured {
                nutritionMessage = "Intake from Apple Health. Sync MyNetDiary to Health, or set MYNETDIARY_API_KEY."
            }
            return
        }
        nutrition = nil
        if !MyNetDiaryConfiguration.isConfigured {
            nutritionMessage = "Not connected. Sync MyNetDiary to Apple Health, or set MYNETDIARY_API_KEY."
        }
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
        if !settings.aiScoringConsent {
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
