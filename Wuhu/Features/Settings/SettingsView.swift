import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDebugJSON = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Data source") {
                    Toggle("Use mock data", isOn: Binding(
                        get: { app.settings.useMockData },
                        set: { newValue in
                            app.settings.useMockData = newValue
                            app.refreshProvider()
                            Task { try? await app.reloadAll(modelContext: modelContext) }
                        }
                    ))
                    Text("Mock mode fills every screen without Apple Health or an API key. You can also pass -useMockData as a launch argument.")
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
                            Task { try? await app.reloadAll(modelContext: modelContext) }
                        }
                    ))
                    Text("When off, Vitality Age and related scores use the on-device calculator only. Only a compact JSON summary is sent — never raw samples.")
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
}

#Preview {
    SettingsView()
        .environment(AppEnvironment())
        .modelContainer(for: [WorkoutRecord.self, ChatMessage.self, BodyPartStatusRecord.self, CachedScoreResult.self], inMemory: true)
}
