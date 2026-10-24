import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @State private var segment: DashboardSegment = .daily
    @State private var showSettings = false
    @State private var showBodyMap = false
    @State private var detailMetric: DashboardMetric?

    enum DashboardSegment: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }

    var body: some View {
        NavigationStack {
            Group {
                if app.isLoading && app.today == nil {
                    VStack(spacing: 12) {
                        SkeletonView()
                        SkeletonView()
                        SkeletonView()
                        SkeletonView()
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Picker("Range", selection: $segment) {
                                ForEach(DashboardSegment.allCases, id: \.self) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Daily or Weekly")

                            if let message = app.errorMessage {
                                Text(message)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if segment == .daily {
                                DailyView(
                                    stats: app.today,
                                    stepGoal: app.settings.stepGoal,
                                    onSelect: { detailMetric = $0 }
                                )
                            } else {
                                WeeklyView(weekly: app.weekly, onSelect: { detailMetric = $0 })
                            }

                            Button {
                                showBodyMap = true
                            } label: {
                                Label("Body Map", systemImage: "figure.stand")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityHint("Opens wear and tear body map")
                        }
                        .padding()
                    }
                    .refreshable {
                        app.refreshProvider()
                        try? await app.reloadAll(modelContext: modelContext)
                    }
                }
            }
            .navigationTitle("Wuhu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(item: $detailMetric) { metric in
                MetricDetailView(metric: metric, history: app.dailyHistory)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(app)
            }
            .navigationDestination(isPresented: $showBodyMap) {
                BodyMapView()
                    .environment(app)
            }
        }
    }
}

enum DashboardMetric: String, Hashable, Identifiable {
    case steps, heartRate, sleep, calories
    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        case .sleep: return "Sleep"
        case .calories: return "Calories"
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppEnvironment())
        .modelContainer(for: [WorkoutRecord.self, ChatMessage.self, BodyPartStatusRecord.self, CachedScoreResult.self], inMemory: true)
}
