import SwiftUI
import SwiftData

/// Read-only log of a finished workout: exactly what was recorded.
struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: HubSession

    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                switch session.kind {
                case .lifting: liftingLog
                case .running: runningLog
                }
            }
            .padding(.horizontal, LayoutMetrics.horizontalMargin)
            .padding(.bottom, LayoutMetrics.bottomScrollInset)
        }
        .background(MeshBackground())
        .navigationTitle(session.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete workout")
            }
        }
        .confirmationDialog("Delete this workout from your log?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                HubSessionService.delete(session, in: modelContext)
                dismiss()
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(session.title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.ink)
            Text(session.startedAt.formatted(date: .complete, time: .shortened))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 12) {
                stat("Duration", HubFormat.elapsed(minutes: session.durationMinutes))
                switch session.kind {
                case .lifting:
                    stat("Sets", "\(session.completedSetCount)")
                    stat("Volume", "\(HomeFormat.grouped(Int(session.totalVolumeLbs.rounded()))) lbs")
                case .running:
                    stat("Distance", HubFormat.miles(session.totalMiles))
                    stat("Avg Pace", session.averagePaceSecondsPerMile.map(HubFormat.pace) ?? "--")
                }
            }
        }
        .padding(LayoutMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppTypography.caption).foregroundStyle(AppColors.textSecondary)
            Text(value).font(AppTypography.cardLabel).foregroundStyle(AppColors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var liftingLog: some View {
        ForEach(session.sortedExercises) { exercise in
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name).font(AppTypography.cardLabel).foregroundStyle(AppColors.ink)
                if let target = exercise.targetLine {
                    Text("Target: \(target)").font(AppTypography.caption).foregroundStyle(AppColors.textSecondary)
                }
                ForEach(exercise.sortedSets) { set in
                    HStack {
                        Text("Set \(set.setNumber)")
                        Spacer()
                        Text("\(set.weightDisplay) lbs × \(set.reps)")
                            .monospacedDigit()
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(set.isCompleted ? AppColors.accent : AppColors.textSecondary)
                            .accessibilityLabel(set.isCompleted ? "Done" : "Not done")
                    }
                    .font(.callout)
                    .foregroundStyle(set.isCompleted ? AppColors.ink : AppColors.textSecondary)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(LayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 16, shadowed: false)
        }
    }

    private var runningLog: some View {
        ForEach(session.sortedSegments) { segment in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(segment.label).font(AppTypography.cardLabel).foregroundStyle(AppColors.ink)
                    Spacer()
                    Image(systemName: segment.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(segment.isCompleted ? AppColors.accent : AppColors.textSecondary)
                        .accessibilityLabel(segment.isCompleted ? "Done" : "Not done")
                }
                HStack(spacing: 12) {
                    stat("Miles", segment.distanceMiles.map(HubFormat.miles) ?? "--")
                    stat("Time", segment.durationSeconds.map(HubFormat.duration) ?? "--")
                    stat("Pace", segment.paceSecondsPerMile.map(HubFormat.pace) ?? "--")
                    stat("Avg HR", segment.averageHeartRate.map { "\(Int($0)) bpm" } ?? "--")
                }
            }
            .padding(LayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 16, shadowed: false)
        }
    }
}
