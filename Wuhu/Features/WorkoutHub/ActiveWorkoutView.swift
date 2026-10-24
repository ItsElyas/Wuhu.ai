import SwiftUI
import SwiftData

/// Full-screen logger for an in-progress session. Edits save immediately, so closing and
/// reopening (or relaunching the app) resumes where the user left off.
struct ActiveWorkoutView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: HubSession

    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var confirmFinish = false
    @State private var confirmDiscard = false

    private var hasLoggedData: Bool {
        session.kind == .lifting ? session.completedSetCount > 0 : !session.completedSegments.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    switch session.kind {
                    case .lifting: liftingSection
                    case .running: runningSection
                    }
                }
                .padding(.horizontal, LayoutMetrics.horizontalMargin)
                .padding(.bottom, LayoutMetrics.bottomScrollInset)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: totalsText) { _, _ in WorkoutLiveActivityController.update(session) }
            .background(MeshBackground())
            .navigationTitle(session.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        minimize()
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Minimize workout")
                    .accessibilityHint("Keeps the workout running in a bubble on the Home screen")
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Menu {
                        Button("Discard Workout", systemImage: "trash", role: .destructive) { confirmDiscard = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More options")
                    Button("Finish") { confirmFinish = true }
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .alert("Add Exercise", isPresented: $showAddExercise) {
                TextField("Exercise name", text: $newExerciseName)
                Button("Add") {
                    HubSessionService.addExercise(named: newExerciseName, to: session, in: modelContext)
                    newExerciseName = ""
                }
                Button("Cancel", role: .cancel) { newExerciseName = "" }
            }
            .confirmationDialog(
                hasLoggedData ? "Finish and save this workout?" : "Nothing is marked done yet",
                isPresented: $confirmFinish,
                titleVisibility: .visible
            ) {
                Button(hasLoggedData ? "Finish Workout" : "Finish Anyway") { finish() }
                Button("Keep Logging", role: .cancel) {}
            } message: {
                Text(hasLoggedData
                     ? "Only sets and segments marked done are counted in your log."
                     : "Tap the circle next to each set or segment you completed so it is saved accurately.")
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) {
                    HubSessionService.delete(session, in: modelContext)
                    dismiss()
                }
            } message: {
                Text("Everything logged in this session will be deleted.")
            }
        }
    }

    private func minimize() {
        WorkoutLiveActivityController.update(session)
        dismiss()
    }

    private func finish() {
        HubSessionService.finish(session, in: modelContext)
        app.refreshWSL(modelContext: modelContext)
        dismiss()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.ink)
            if let cue = session.cue {
                Text(cue)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(HubFormat.duration(max(0, context.date.timeIntervalSince(session.startedAt))))
                        .font(.system(.title3, design: .monospaced))
                        .accessibilityLabel("Elapsed time")
                }
                Spacer()
                Text(totalsText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(LayoutMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var totalsText: String {
        switch session.kind {
        case .lifting:
            return "\(session.completedSetCount) sets · \(HomeFormat.grouped(Int(session.totalVolumeLbs.rounded()))) lbs"
        case .running:
            var text = HubFormat.miles(session.totalMiles)
            if let pace = session.averagePaceSecondsPerMile { text += " · \(HubFormat.pace(pace))" }
            return text
        }
    }

    // MARK: - Lifting

    private var liftingSection: some View {
        VStack(spacing: 12) {
            ForEach(session.sortedExercises) { exercise in
                LiftExerciseCard(exercise: exercise)
            }
            Button {
                showAddExercise = true
            } label: {
                Label("Add Exercise", systemImage: "plus")
                    .font(AppTypography.cardLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
    }

    // MARK: - Running

    private var runningSection: some View {
        VStack(spacing: 12) {
            ForEach(session.sortedSegments) { segment in
                RunSegmentCard(segment: segment)
            }
            Button {
                HubSessionService.addSegment(to: session, in: modelContext)
            } label: {
                Label("Add Run Segment", systemImage: "plus")
                    .font(AppTypography.cardLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
    }
}
