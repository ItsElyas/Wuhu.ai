import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @State private var showAIConsent = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "heart.text.square") }
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "figure.run") }
            ChatScreen()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            VitalityAgeScreen()
                .tabItem { Label("Vitality", systemImage: "sparkles") }
        }
        .task {
            seedMockBodyStatusIfNeeded()
            await app.bootstrap(modelContext: modelContext)
            if !app.settings.aiConsentShown {
                showAIConsent = true
            }
        }
        .sheet(isPresented: $showAIConsent) {
            AIConsentView(isPresented: $showAIConsent)
                .environment(app)
                .presentationDetents([.medium])
        }
    }

    private func seedMockBodyStatusIfNeeded() {
        guard app.settings.useMockData else { return }
        let existing = (try? modelContext.fetch(FetchDescriptor<BodyPartStatusRecord>())) ?? []
        guard existing.isEmpty else { return }
        modelContext.insert(
            BodyPartStatusRecord(
                part: .leftQuad,
                status: .sore,
                severity: 3,
                note: "After tempo run",
                startedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
                source: .manual,
                intensity: 0.8
            )
        )
        modelContext.insert(
            BodyPartStatusRecord(
                part: .rightKnee,
                status: .injured,
                severity: 2,
                note: "Marked by you",
                startedAt: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
                source: .manual,
                intensity: 1
            )
        )
        modelContext.insert(
            BodyPartStatusRecord(
                part: .chest,
                status: .worked,
                severity: 1,
                startedAt: Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now,
                source: .autoWorkout,
                intensity: 0.7
            )
        )
        try? modelContext.save()
    }
}
