import SwiftUI
import SwiftData

/// Weekly Stats destination. Shows the running layout until profile sports exist.
struct WeeklyPerformanceContainerView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var loggedWorkouts: [WorkoutRecord]
    @Query(sort: \HubSession.startedAt, order: .reverse) private var hubSessions: [HubSession]

    private var mode: WeeklyPerformanceMode {
        app.profilePreferences.weeklyPerformanceMode
    }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleBlock
                    #if DEBUG
                    previewPicker
                    #endif
                    switch mode {
                    case .running:
                        WeeklyRunningProgressView(display: runningDisplay, intakeLine: intakeLine)
                    case .powerlifting:
                        WeeklyPowerliftingProgressView(display: powerliftingDisplay)
                    }
                    detailedStatsButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .font(AppTypography.homeTitle)
                    .foregroundStyle(AppColors.ink)
                }
                .accessibilityLabel("Home")
            }
            ToolbarItem(placement: .topBarTrailing) {
                datePill
            }
        }
        .preferredColorScheme(.light)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            (
                Text(titleLead + "\n")
                    .foregroundStyle(AppColors.ink)
                + Text("Progress")
                    .foregroundStyle(AppColors.accent)
            )
            .font(AppTypography.weeklyTitle)
            .lineSpacing(0)
            Text(tagline)
                .font(AppTypography.homeCaption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var titleLead: String {
        switch mode {
        case .running: return RunningWeeklyFixture.titleLead
        case .powerlifting: return PowerliftingWeeklyFixture.titleLead
        }
    }

    private var tagline: String {
        switch mode {
        case .running: return RunningWeeklyFixture.tagline
        case .powerlifting: return PowerliftingWeeklyFixture.tagline
        }
    }

    private var datePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
            Text(weekLabel)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .font(AppTypography.pillLabel)
        .foregroundStyle(AppColors.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.72), in: Capsule())
        .overlay(Capsule().strokeBorder(AppColors.cardStroke, lineWidth: 1))
        .accessibilityLabel("Week of \(weekLabel)")
    }

    private var runningDisplay: RunningWeekDisplay {
        RunningWeekBuilder.make(workouts: app.recentWorkouts, daily: app.dailyHistory)
    }

    private var powerliftingDisplay: PowerliftingWeekDisplay {
        PowerliftingWeekBuilder.make(sessions: hubSessions, logged: loggedWorkouts, profileWeightKg: app.profile.weightKg)
    }

    private var weekLabel: String {
        switch mode {
        case .running: return runningDisplay.dateRange
        case .powerlifting: return powerliftingDisplay.dateRange
        }
    }

    private var intakeLine: String? {
        guard let nutrition = app.nutrition else { return nil }
        guard nutrition.todayCaloriesIn != nil || nutrition.weekCaloriesIn != nil else { return nil }
        let today = nutrition.todayCaloriesIn.map { "\(HomeFormat.grouped($0)) today" } ?? "-- today"
        let week = nutrition.weekCaloriesIn.map { "\(HomeFormat.grouped($0)) this week" } ?? "-- this week"
        var line = "Calories in · \(today) · \(week)"
        if let macros = nutrition.macroLine {
            line += " · \(macros)"
        }
        return line
    }

    #if DEBUG
    private var previewPicker: some View {
        Picker("Weekly preview", selection: Binding(
            get: { app.profilePreferences.weeklyPerformanceMode },
            set: { app.profilePreferences.weeklyPerformanceMode = $0 }
        )) {
            ForEach(WeeklyPerformanceMode.allCases) { item in
                Text(item.previewTitle).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Weekly preview")
    }
    #endif

    private var detailedStatsButton: some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                Text("View Detailed Stats")
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .font(AppTypography.homeTitle)
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.white.opacity(0.45), in: Capsule())
            .overlay(Capsule().strokeBorder(AppColors.cardStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View Detailed Stats")
    }
}
