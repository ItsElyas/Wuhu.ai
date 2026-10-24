import SwiftUI

struct WeeklyPowerliftingProgressView: View {
    var display: PowerliftingWeekDisplay
    @State private var showAddLift = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let message = display.placeholderMessage {
                Text(message)
                    .font(AppTypography.homeCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            statsRow
            liftsCard
            recordsCard(
                title: "Recent PRs",
                subtitle: "New personal records",
                systemImage: "trophy.fill",
                tint: Color(hex: 0xE0A106),
                rows: display.prs,
                emptyText: "No PRs yet",
                showTrend: true
            )
            recordsCard(
                title: "Last Workout",
                subtitle: display.lastWorkoutSubtitle,
                systemImage: "dumbbell.fill",
                tint: Color(hex: 0x7A5AF8),
                rows: display.lastWorkoutRows,
                emptyText: "—",
                showTrend: false
            )
        }
        .alert("Add Lift", isPresented: $showAddLift) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Lift logging is not available yet.")
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(display.stats) { metric in
                WeeklyMetricCard(metric: metric)
            }
        }
    }

    private var liftsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Powerlifting Lifts")
                        .font(AppTypography.homeTitle)
                        .foregroundStyle(AppColors.ink)
                    Text("Track your 1RM and see your progress")
                        .font(AppTypography.backNote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer(minLength: 8)
                Button {
                    showAddLift = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Lift")
                    }
                    .font(AppTypography.pillLabel)
                    .foregroundStyle(Color(hex: 0x7A5AF8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0x7A5AF8).opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Lift")
            }
            HStack(alignment: .top, spacing: 8) {
                ForEach(display.lifts) { lift in
                    liftCard(lift)
                }
            }
        }
        .padding(16)
        .glassCard(radius: 26)
    }

    private func liftCard(_ lift: LiftProgress) -> some View {
        let tint = Color(hex: lift.tintHex)
        let trendColor = lift.favorable ? Color(hex: 0x1FA971) : AppColors.accent
        return VStack(alignment: .leading, spacing: 4) {
            Image(systemName: lift.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.16), in: Circle())
            Text(lift.name)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(lift.value)
                .font(AppTypography.weeklyValue)
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("1RM (est.)")
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
            HStack(spacing: 2) {
                Image(systemName: lift.trendSymbol)
                    .font(.system(size: 9, weight: .bold))
                Text(lift.trend)
                    .font(AppTypography.weeklyDelta)
            }
            .foregroundStyle(trendColor)
            Text("vs. last week")
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lift.name), \(lift.value) estimated one rep max, \(lift.trend) versus last week")
    }

    private func recordsCard(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        rows: [LiftRecord],
        emptyText: String,
        showTrend: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.homeTitle)
                        .foregroundStyle(AppColors.ink)
                    Text(subtitle)
                        .font(AppTypography.backNote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            if rows.isEmpty {
                Text(emptyText)
                    .font(AppTypography.rowValue)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.name)
                                .font(AppTypography.backNote)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 4) {
                                Text(row.value)
                                    .font(AppTypography.rowValue)
                                    .foregroundStyle(AppColors.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                if showTrend {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x1FA971))
                                }
                            }
                            Text(row.note)
                                .font(AppTypography.backNote)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(16)
        .glassCard(radius: 26)
    }
}

#Preview("Powerlifting") {
    ScrollView {
        WeeklyPowerliftingProgressView(display: PowerliftingWeekBuilder.placeholder())
            .padding()
    }
    .background(MeshBackground())
}
