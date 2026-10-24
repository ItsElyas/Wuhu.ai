import SwiftUI
import SwiftData

/// Workout Hub: Start Workout → pick Running or Lifting → regimen → log → Workout Log history.
struct WorkoutHubView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HubSession.startedAt, order: .reverse) private var sessions: [HubSession]

    @State private var showStart = false
    /// Set when the start sheet creates a session; the logger opens after the sheet dismisses.
    @State private var openLoggerAfterSheet = false

    private var inProgress: HubSession? { sessions.first(where: \.isActive) }
    private var history: [HubSession] { sessions.filter { !$0.isActive } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Workout Hub")
                    .font(AppTypography.greeting)
                    .foregroundStyle(AppColors.ink)

                Text(WorkoutPlanService.todayPillLabel(profile: app.playerProfileStore.profile, plan: nil))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.navRowFill.opacity(0.6), in: Capsule())

                if let inProgress {
                    resumeCard(inProgress)
                } else {
                    startButton
                }

                historySection
            }
            .padding(.horizontal, LayoutMetrics.horizontalMargin)
            .padding(.bottom, LayoutMetrics.bottomScrollInset)
        }
        .background(MeshBackground())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStart, onDismiss: {
            if openLoggerAfterSheet {
                openLoggerAfterSheet = false
                app.isWorkoutLoggerPresented = true
            }
        }) {
            StartWorkoutSheet { regimen in
                HubSessionService.start(regimen, in: modelContext)
                openLoggerAfterSheet = true
                showStart = false
            }
            .environment(app)
        }
    }

    private var startButton: some View {
        Button {
            showStart = true
        } label: {
            Label("Start Workout", systemImage: "play.fill")
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)
        .accessibilityHint("Choose running or lifting, then log your workout")
    }

    private func resumeCard(_ session: HubSession) -> some View {
        Button {
            app.isWorkoutLoggerPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Workout in progress", systemImage: session.kind.symbol)
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(AppColors.textSecondary)
                Text(session.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.leading)
                Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened)) · Tap to resume")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(LayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Resume \(session.title)")
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workout Log")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.ink)
            if history.isEmpty {
                Text("Finished workouts appear here with every set, weight, distance, and pace you logged.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(LayoutMetrics.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(radius: 16, shadowed: false)
            } else {
                ForEach(history) { session in
                    NavigationLink {
                        WorkoutSessionDetailView(session: session)
                    } label: {
                        WorkoutHistoryRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// One finished workout in the log list.
struct WorkoutHistoryRow: View {
    let session: HubSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.kind.symbol)
                .font(.title3)
                .foregroundStyle(AppColors.accent)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
                Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(HubFormat.elapsed(minutes: session.durationMinutes))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(HubSessionService.summary(session))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(LayoutMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 16, shadowed: false)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        WorkoutHubView()
            .environment(AppEnvironment())
    }
    .modelContainer(for: [HubSession.self, HubExercise.self, HubSetLog.self, HubRunSegment.self, WorkoutRecord.self], inMemory: true)
}
