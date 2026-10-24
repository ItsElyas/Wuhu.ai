import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var bodyRecords: [BodyPartStatusRecord]

    @State private var model = HomeViewModel()
    @State private var showChat = false
    @State private var showSettings = false
    @State private var showWSL = false
    @State private var detailMetric: DashboardMetric?
    @State private var route: HomeRoute?

    private var stacked: Bool { dynamicTypeSize >= .accessibility1 }
    private var state: HomeState { model.state }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                if state.phase == .loading {
                    skeleton
                } else {
                    scroll
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.ink)
                            .frame(width: LayoutMetrics.avatarSize, height: LayoutMetrics.avatarSize)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(item: $route) { route in
                switch route {
                case .weekly:
                    WeeklyPerformanceContainerView()
                case .workoutHub:
                    WorkoutHubView()
                case .workouts:
                    WorkoutListView()
                case .bodyMap:
                    BodyMapView()
                        .environment(app)
                        .navigationTitle("Wear & Tear")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationDestination(item: $detailMetric) { metric in
                MetricDetailView(metric: metric, history: app.dailyHistory)
            }
            .sheet(isPresented: $showChat) {
                ChatView()
                    .environment(app)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(app)
            }
            .sheet(isPresented: $showWSL) {
                WSLScoreSheet(
                    scores: app.latestScores,
                    presentation: state.wslPresentation,
                    evaluation: app.currentWSLEvaluation
                )
                    .presentationDetents([.medium, .large])
            }
        }
        .preferredColorScheme(.light)
        .onAppear { model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext) }
        .onChange(of: app.today) { _, _ in model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext) }
        .onChange(of: app.latestScores) { _, _ in model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext) }
        .onChange(of: app.nutrition) { _, _ in model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext) }
        .onChange(of: app.isLoading) { _, _ in model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext) }
        .onChange(of: app.reloadGeneration) { _, _ in model.reload(app: app, records: Array(bodyRecords)) }
        .onChange(of: bodyRecords.count) { _, _ in
            model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext)
        }
        .onChange(of: app.playerProfileStore.profile?.selectedSport) { _, _ in
            app.syncWeeklyPerformanceFromProfile()
            model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext)
        }
    }

    private var scroll: some View {
        ScrollView {
            VStack(spacing: LayoutMetrics.sectionSpacing) {
                if case .error(let message) = state.phase {
                    errorBanner(message)
                }
                #if DEBUG
                dataSourceDebugBanner
                #endif
                if let caption = state.dataCaption {
                    Text(caption)
                        .font(AppTypography.homeCaption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GreetingHeader(copy: GreetingCopy.make(firstName: state.firstName, plan: state.plan))
                    .padding(.top, LayoutMetrics.greetingTop)
                    .padding(.bottom, LayoutMetrics.greetingBottom - LayoutMetrics.sectionSpacing)

                if stacked {
                    VStack(spacing: LayoutMetrics.cardGap) {
                        wslCard
                        sleepCard
                    }
                } else {
                    HStack(alignment: .top, spacing: LayoutMetrics.cardGap) {
                        wslCard
                        sleepCard
                    }
                }

                WearAndTearCard(
                    state: state,
                    reduceMotion: reduceMotion,
                    stacked: stacked,
                    onBody: { push(.bodyMap) },
                    onSteps: { detailMetric = .steps },
                    onCalories: { detailMetric = .calories },
                    onRecovery: { showWSL = true }
                )

                NavRow(title: "Weekly Stats", leadingIcon: "chart.bar", trailingIcon: "chevron.right") {
                    push(.weekly)
                }

                HStack(spacing: LayoutMetrics.fabGap) {
                    NavRow(title: "Workout Hub", leadingIcon: nil, trailingIcon: "dumbbell") {
                        push(.workoutHub)
                    }
                    ChatFAB { showChat = true }
                }
            }
            .padding(.horizontal, LayoutMetrics.horizontalMargin)
            .padding(.bottom, LayoutMetrics.bottomScrollInset)
        }
        .refreshable {
            app.refreshProvider()
            await app.reloadReportingErrors(modelContext: modelContext)
            model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext)
        }
    }

    #if DEBUG
    private var dataSourceDebugBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Data source: \(app.homeDataSourceLabel.rawValue)")
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.ink)
            if let error = app.errorMessage {
                Text("Last reload: \(error)")
                    .font(AppTypography.backNote)
                    .foregroundStyle(AppColors.accent)
            } else if let finished = app.lastReloadFinishedAt {
                Text("Last reload: OK · \(finished.formatted(date: .omitted, time: .shortened))")
                    .font(AppTypography.backNote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .glassCard(radius: 12, shadowed: false)
        .accessibilityElement(children: .combine)
    }
    #endif

    private var wslCard: some View {
        WSLScoreCard(presentation: state.wslPresentation, onTap: { showWSL = true })
    }

    private var sleepCard: some View {
        SleepCard(
            total: sleepTitle,
            deep: sleepDeep,
            spoken: sleepSpoken,
            onTap: { detailMetric = .sleep }
        )
    }

    private var sleepTitle: String {
        guard let sleep = state.sleep else { return "--" }
        return HomeFormat.sleep(hours: sleep.totalHours)
    }

    private var sleepDeep: String? {
        guard let sleep = state.sleep else { return nil }
        guard let deep = sleep.deepHours else { return "No sleep data" }
        return "Deep \(HomeFormat.sleep(hours: deep))"
    }

    private var sleepSpoken: String {
        guard let sleep = state.sleep else { return "Sleep, no sleep data" }
        return "Sleep \(spokenDuration(sleep.totalHours)), deep sleep \(spokenDuration(sleep.deepHours ?? 0))"
    }

    private func spokenDuration(_ hours: Double) -> String {
        let minutes = max(0, Int((hours * 60).rounded()))
        let hourPart = minutes / 60
        let minutePart = minutes % 60
        if hourPart == 0 { return "\(minutePart) minutes" }
        return "\(hourPart) hours \(minutePart) minutes"
    }

    private var skeleton: some View {
        VStack(spacing: LayoutMetrics.sectionSpacing) {
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.5)).frame(height: 90)
            HStack(spacing: LayoutMetrics.cardGap) {
                RoundedRectangle(cornerRadius: LayoutMetrics.cardRadius).fill(.white.opacity(0.5)).frame(height: LayoutMetrics.topCardHeight)
                RoundedRectangle(cornerRadius: LayoutMetrics.cardRadius).fill(.white.opacity(0.5)).frame(height: LayoutMetrics.topCardHeight)
            }
            RoundedRectangle(cornerRadius: LayoutMetrics.wearRadius).fill(.white.opacity(0.5)).frame(height: LayoutMetrics.wearHeight)
            Capsule().fill(.white.opacity(0.45)).frame(height: LayoutMetrics.navHeight)
            Capsule().fill(.white.opacity(0.45)).frame(height: LayoutMetrics.navHeight)
        }
        .padding(.horizontal, LayoutMetrics.horizontalMargin)
        .padding(.top, 24)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(AppTypography.homeCaption)
                .foregroundStyle(AppColors.ink)
            Spacer()
            Button("Retry") {
                Task {
                    await app.reloadReportingErrors(modelContext: modelContext)
                    model.reload(app: app, records: Array(bodyRecords), modelContext: modelContext)
                }
            }
            .font(AppTypography.rowValue)
        }
        .padding(12)
        .glassCard(radius: 16, shadowed: false)
    }

    private func push(_ next: HomeRoute) {
        route = next
    }
}

enum HomeRoute: Hashable {
    case weekly
    case workoutHub
    case workouts
    case bodyMap
}

private struct WSLScoreSheet: View {
    var scores: ScoreResult?
    var presentation: WSLScorePresentation
    var evaluation: WSLCompositeEvaluation?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(presentation.headline)
                        .font(AppTypography.greeting)
                        .foregroundStyle(AppColors.ink)
                        .accessibilityLabel("WSL Score, \(presentation.headline)")
                    if let detail = presentation.detail {
                        Text(detail)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let evaluation {
                        Text(evaluation.feedbackComment)
                            .font(AppTypography.homeCaption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("Confidence: \(evaluation.confidencePercentage)%\(evaluation.isProvisional ? " (provisional)" : "")")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let summary = scores?.egoScore?.summary {
                        Text(summary)
                            .font(AppTypography.homeCaption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let readiness = scores?.readiness {
                        breakdownRow(
                            "Readiness",
                            VitalityAgePresentation.scoreText(readiness.score),
                            readiness.summary
                        )
                    }
                    if let effort = scores?.effort {
                        breakdownRow(
                            "Effort",
                            VitalityAgePresentation.effortText(score: effort.score, scaleMax: effort.scaleMax),
                            effort.summary
                        )
                    }
                    if let sleep = scores?.sleepScore {
                        breakdownRow(
                            "Sleep Score",
                            VitalityAgePresentation.scoreText(sleep.score),
                            sleep.summary
                        )
                    }
                    if let years = scores?.vitalityAge?.years, let delta = scores?.vitalityAge?.deltaVsChronological {
                        Text("Vitality Age \(String(format: "%.1f", years))")
                            .font(AppTypography.homeTitle)
                        Text(VitalityAgePresentation.deltaLabel(delta: delta))
                            .foregroundStyle(VitalityAgePresentation.deltaColor(delta: delta))
                    }
                    if let method = scores?.method {
                        Text(method)
                            .font(AppTypography.homeCaption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let drivers = scores?.vitalityAge?.drivers {
                        ForEach(drivers) { driver in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(driver.metric.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(AppTypography.rowValue)
                                if let note = driver.note {
                                    Text(note)
                                        .font(AppTypography.homeCaption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                    Text(scores?.disclaimer ?? "Estimate for motivation only, not medical advice.")
                        .font(AppTypography.homeCaption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("WSL Score")
            .navigationBarTitleDisplayMode(.inline)
            .background(MeshBackground())
        }
    }

    private func breakdownRow(_ title: String, _ value: String, _ detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(AppTypography.rowValue)
                Spacer()
                Text(value)
                    .font(AppTypography.rowValue)
            }
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(AppTypography.homeCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview("Reference") {
    HomePreviewHost(state: HomeFixture.reference)
}

#Preview("Loading") {
    HomePreviewHost(state: .loading)
}

#Preview("Empty") {
    HomePreviewHost(state: HomeFixture.empty)
}

#Preview("Large type") {
    HomePreviewHost(state: HomeFixture.reference)
        .dynamicTypeSize(.accessibility2)
}

#Preview("SE") {
    HomePreviewHost(state: HomeFixture.reference)
        .frame(width: 320, height: 568)
}

private struct HomePreviewHost: View {
    var state: HomeState

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    if state.phase != .loading {
                        GreetingHeader(copy: GreetingCopy.make(firstName: state.firstName, plan: state.plan))
                        HStack(spacing: LayoutMetrics.cardGap) {
                            WSLScoreCard(presentation: state.wslPresentation, onTap: {})
                            SleepCard(
                                total: state.sleep.map { HomeFormat.sleep(hours: $0.totalHours) } ?? "--",
                                deep: state.sleep?.deepHours.map { "Deep \(HomeFormat.sleep(hours: $0))" },
                                spoken: "Sleep",
                                onTap: {}
                            )
                        }
                        WearAndTearCard(state: state, reduceMotion: true, stacked: false, onBody: {}, onSteps: {}, onCalories: {}, onRecovery: {})
                        NavRow(title: "Weekly Stats", leadingIcon: "chart.bar", trailingIcon: "chevron.right", onTap: {})
                        HStack(spacing: 10) {
                            NavRow(title: "Workout Hub", leadingIcon: nil, trailingIcon: "dumbbell", onTap: {})
                            ChatFAB(onTap: {})
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.light)
    }
}
