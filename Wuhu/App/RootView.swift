import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAIConsent = false
    @Query(filter: #Predicate<HubSession> { $0.endedAt == nil }, sort: \HubSession.startedAt, order: .reverse)
    private var activeSessions: [HubSession]

    private var activeSession: HubSession? { activeSessions.first }

    var body: some View {
        @Bindable var app = app
        HomeView()
            .overlay {
                if let activeSession, !app.isWorkoutLoggerPresented {
                    ActiveWorkoutBubble(session: activeSession) {
                        app.isWorkoutLoggerPresented = true
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: activeSession?.id)
            .fullScreenCover(isPresented: $app.isWorkoutLoggerPresented) {
                if let activeSession {
                    ActiveWorkoutView(session: activeSession)
                        .environment(app)
                }
            }
            .onChange(of: activeSession?.id) { _, newValue in
                // Logger closes itself when the workout is finished or discarded.
                if newValue == nil { app.isWorkoutLoggerPresented = false }
            }
            .onOpenURL { url in
                guard WorkoutDeepLink.isWorkoutURL(url), activeSession != nil else { return }
                app.isWorkoutLoggerPresented = true
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    WorkoutLiveActivityController.reconcile(activeSession: activeSession)
                }
            }
            .task {
                WorkoutLiveActivityController.reconcile(activeSession: activeSession)
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
}
