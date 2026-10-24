import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDebugJSON = false
    @State private var geminiProbeInFlight = false
    @State private var wooSport: AthleteOnboardingEngine.SportDiscipline = .powerlifting
    @State private var wooGender: AthleteOnboardingEngine.Gender = .male

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Demo mode", isOn: Binding(
                        get: { app.settings.demoMode },
                        set: { newValue in
                            guard newValue != app.settings.demoMode else { return }
                            if newValue { ModelContainerStore.shared.resetDemo() }
                            app.resetLoadedState()
                            app.settings.demoMode = newValue
                            app.refreshProvider()
                        }
                    ))
                    .accessibilityHint("Switches the whole app to sample data")
                } header: {
                    Text("Demo")
                } footer: {
                    Text(app.settings.demoMode
                         ? "Showing sample data: 30 days of health stats, runs and lifts in the Workout Log, Body Map statuses (injured right knee), and nutrition. Anything you log now is discarded when demo mode turns off. Your real data is untouched."
                         : "Fills the app with sample health data, workouts, and Body Map statuses for demos. Your real data is kept separately and comes back when you turn this off.")
                }

                Section("Apple Health") {
                    LabeledContent("Data status", value: app.homeDataSourceLabel.rawValue)
                    if let error = app.errorMessage {
                        Text("Last reload error: \(error)")
                            .font(AppTypography.caption)
                            .foregroundStyle(.red)
                    }
                    if let hint = app.healthAccessHint {
                        Text(hint)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Wuhu reads Apple Health on your iPhone. Use a real device with Health permissions granted. Empty metrics show as dashes until data exists.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Section("MyNetDiary") {
                    LabeledContent("Status", value: app.nutritionMessage)
                    if let today = app.nutrition?.todayCaloriesIn {
                        LabeledContent("Calories in today", value: HomeFormat.grouped(today))
                    }
                    Text("MyNetDiary does not publish a personal diary API. With MYNETDIARY_API_KEY, Wuhu calls GET /v1/diary/days. Otherwise calories in come from Apple Health dietary energy, which MyNetDiary can write when Health sync is on.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Section("AI scoring") {
                    Toggle("Send health summary to AI", isOn: Binding(
                        get: { app.settings.aiScoringConsent },
                        set: { newValue in
                            app.settings.aiScoringConsent = newValue
                            app.settings.aiConsentShown = true
                            app.refreshProvider()
                            Task { await app.reloadReportingErrors(modelContext: modelContext) }
                        }
                    ))
                    Toggle("Chat wellness check-in", isOn: Binding(
                        get: { app.settings.chatWellnessCheckInEnabled },
                        set: { app.settings.chatWellnessCheckInEnabled = $0 }
                    ))
                    Text("When off, Vitality Age and related scores use the on-device calculator only. Only a compact JSON summary is sent — never raw samples.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text("With AI on and a Gemini key set, chat uses Gemini and can update Body Map wear from what you say (e.g. “my right knee hurts”).")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Wuhu profile (stub)") {
                    Picker("Sport", selection: $wooSport) {
                        ForEach(AthleteOnboardingEngine.SportDiscipline.allCases, id: \.self) { sport in
                            Text(sport.rawValue).tag(sport)
                        }
                    }
                    Picker("Gender", selection: $wooGender) {
                        ForEach(AthleteOnboardingEngine.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    if let profile = app.playerProfileStore.profile {
                        LabeledContent("Saved as", value: profile.name)
                        if let eval = profile.wslEvaluation {
                            LabeledContent("WSL", value: "\(eval.rank.title) · \(String(format: "%.2f", eval.compositeScore))")
                        }
                    }
                    Button("Save profile + sample WSL") {
                        saveWuhuProfile(includeSampleWSL: true)
                    }
                    Button("Save sport only (no WSL)", role: .destructive) {
                        saveWuhuProfile(includeSampleWSL: false)
                    }
                    Text("Drives Home WSL Score, Weekly Stats layout, workout bank sport, and Gemini dossier until full onboarding ships.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .onAppear {
                    wooSport = app.playerProfileStore.profile?.selectedSport ?? .powerlifting
                    wooGender = app.playerProfileStore.profile?.gender ?? .male
                }

                Section("Gemini chat") {
                    LabeledContent("Status", value: GeminiChatDiagnostics.statusLabel(aiScoringConsent: app.settings.aiScoringConsent))
                    if let detail = GeminiChatDiagnostics.statusDetail(aiScoringConsent: app.settings.aiScoringConsent) {
                        Text(detail)
                            .font(AppTypography.caption)
                            .foregroundStyle(GeminiChatDiagnostics.lastError == nil ? Color.secondary : Color.red)
                    }
                    LabeledContent("Model", value: GeminiConfiguration.model)
                    LabeledContent("Endpoint", value: GeminiConfiguration.baseURLString)
                    Button {
                        geminiProbeInFlight = true
                        Task {
                            await app.probeGeminiChatConnection()
                            geminiProbeInFlight = false
                        }
                    } label: {
                        if geminiProbeInFlight {
                            HStack {
                                ProgressView()
                                Text("Testing…")
                            }
                        } else {
                            Text("Test Gemini connection")
                        }
                    }
                    .disabled(!GeminiConfiguration.isConfigured || !app.settings.aiScoringConsent || geminiProbeInFlight)
                    Text("Uses GEMINI_API_KEY from Secrets.xcconfig (embedded at build time). Keys starting with AQ. or AIza use the Generative Language API URL above — not localhost or Vertex unless you change GEMINI_BASE_URL.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Profile") {
                    Stepper("Age: \(app.settings.chronologicalAge)", value: Binding(
                        get: { app.settings.chronologicalAge },
                        set: { app.settings.chronologicalAge = $0 }
                    ), in: 13...100)
                    Picker("Sex", selection: Binding(
                        get: { app.settings.biologicalSex },
                        set: { app.settings.biologicalSex = $0 }
                    )) {
                        Text("Female").tag("female")
                        Text("Male").tag("male")
                        Text("Other").tag("other")
                    }
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("cm", value: Binding(
                            get: { app.settings.heightCm },
                            set: { app.settings.heightCm = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("kg", value: Binding(
                            get: { app.settings.weightKg },
                            set: { app.settings.weightKg = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                    Stepper("Step goal: \(app.settings.stepGoal)", value: Binding(
                        get: { app.settings.stepGoal },
                        set: { app.settings.stepGoal = $0 }
                    ), in: 1_000...30_000, step: 500)
                }

                #if DEBUG
                Section("Debug") {
                    Picker("Weekly preview", selection: Binding(
                        get: { app.profilePreferences.weeklyPerformanceMode },
                        set: { app.profilePreferences.weeklyPerformanceMode = $0 }
                    )) {
                        ForEach(WeeklyPerformanceMode.allCases) { mode in
                            Text(mode.previewTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Weekly preview: Running | Powerlifting. Profile sports are not wired yet, so this only changes the Weekly Stats screen.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Button("View data sent") { showDebugJSON = true }
                }
                #endif

                Section("Disclaimer") {
                    Text("HealthTracker is a wellness tool for motivation. It is not a medical device and does not provide diagnosis or treatment.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showDebugJSON) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Snapshot").font(AppTypography.headline)
                            Text(app.settings.lastSnapshotJSON.isEmpty ? "(empty)" : app.settings.lastSnapshotJSON)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                            Text("ScoreResult").font(AppTypography.headline)
                            Text(app.settings.lastScoreJSON.isEmpty ? "(empty)" : app.settings.lastScoreJSON)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding()
                    }
                    .navigationTitle("Data sent")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showDebugJSON = false }
                        }
                    }
                }
            }
        }
    }

    private func saveWuhuProfile(includeSampleWSL: Bool) {
        let age = app.settings.chronologicalAge
        let weightLbs = app.settings.weightKg * 2.20462
        let heightInches = app.settings.heightCm / 2.54
        let evaluation: WSLCompositeEvaluation?
        if includeSampleWSL {
            switch wooSport {
            case .running:
                evaluation = AthleteOnboardingEngine.evaluateCompositeWSL(
                    sport: .running,
                    gender: wooGender,
                    age: age,
                    bodyweightLbs: weightLbs,
                    heightInches: heightInches,
                    primaryVal: wooGender == .male ? 22.5 : 25.0,
                    subMetricA: 58,
                    subMetricB: nil
                )
            case .powerlifting:
                evaluation = AthleteOnboardingEngine.evaluateCompositeWSL(
                    sport: .powerlifting,
                    gender: wooGender,
                    age: age,
                    bodyweightLbs: weightLbs,
                    heightInches: heightInches,
                    primaryVal: wooGender == .male ? 1050 : 650,
                    subMetricA: wooGender == .male ? 385 : 245,
                    subMetricB: wooGender == .male ? 265 : 155
                )
            }
        } else {
            evaluation = nil
        }
        guard let profile = try? AthleteOnboardingEngine.makeProfile(
            name: app.profile.displayName ?? "Athlete",
            gender: wooGender,
            age: age,
            heightInches: heightInches,
            weightLbs: weightLbs,
            activityLevel: .moderatelyActive,
            selectedSport: wooSport,
            wslEvaluation: evaluation
        ) else { return }
        app.playerProfileStore.save(profile)
        app.syncWeeklyPerformanceFromProfile()
    }
}

#Preview {
    SettingsView()
        .environment(AppEnvironment())
        .modelContainer(for: [WorkoutRecord.self, ChatMessage.self, BodyPartStatusRecord.self, CachedScoreResult.self, HubExercise.self, HubSetLog.self], inMemory: true)
}
