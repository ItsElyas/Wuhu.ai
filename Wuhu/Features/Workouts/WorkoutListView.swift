import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var workouts: [WorkoutRecord]
    @State private var showAdd = false

    var body: some View {
        List {
                Section {
                    weeklySummary
                }

                Section("Workouts") {
                    if workouts.isEmpty {
                        ContentUnavailableView(
                            "No workouts yet",
                            systemImage: "figure.run",
                            description: Text("Add a workout or import from Apple Health.")
                        )
                    } else {
                        ForEach(workouts) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout)
                            } label: {
                                WorkoutRow(workout: workout)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add workout")
                }
            }
            .sheet(isPresented: $showAdd) {
                WorkoutLogView()
            }
    }

    private var weeklySummary: some View {
        weeklySummaryContent(workouts: Array(workouts))
    }

    private func weeklySummaryContent(workouts: [WorkoutRecord]) -> some View {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let week = workouts.filter { $0.startDate >= weekStart }
        let minutes = week.reduce(0.0) { $0 + $1.durationMinutes }
        let calories = week.compactMap(\.calories).reduce(0, +)
        return HStack {
            summaryChip(title: "Sessions", value: "\(week.count)")
            summaryChip(title: "Minutes", value: "\(Int(minutes))")
            summaryChip(title: "Calories", value: "\(Int(calories))")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppTypography.metricValue)
            Text(title).font(AppTypography.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
        try? modelContext.save()
    }
}

struct WorkoutRow: View {
    var workout: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workout.type.capitalized)
                    .font(AppTypography.headline)
                Spacer()
                Text(workout.startDate, style: .date)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(workout.durationMinutes)) min · \(workout.calories.map { "\(Int($0)) kcal" } ?? "—") · \(workout.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—")")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        WorkoutListView()
    }
    .environment(AppEnvironment())
    .modelContainer(for: [WorkoutRecord.self, BodyPartStatusRecord.self, ChatMessage.self, CachedScoreResult.self], inMemory: true)
}
