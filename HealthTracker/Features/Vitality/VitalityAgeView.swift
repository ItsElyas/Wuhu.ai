import SwiftUI

struct VitalityAgeView: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if app.latestScores?.insufficientData == true || app.latestScores?.vitalityAge?.years == nil {
                        collectingCard
                    } else {
                        ageCard
                    }

                    scoresRow
                    driversSection

                    if app.usedLocalFallback {
                        Text("Estimated locally")
                            .font(AppTypography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2), in: Capsule())
                            .accessibilityLabel("Scores estimated locally")
                    }

                    Text(app.latestScores?.disclaimer
                         ?? "Estimate for motivation only, not a medical measurement.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Vitality Age")
        }
    }

    private var collectingCard: some View {
        collectingCardContent(days: app.lastSnapshot?.dataQuality.daysWithData ?? 0)
    }

    private func collectingCardContent(days: Int) -> some View {
        VStack(spacing: 8) {
            Text("Collecting data")
                .font(AppTypography.title)
            Text("\(days)/\(VitalityConfig.minimumDaysOfData) days")
                .font(AppTypography.metricValue)
                .foregroundStyle(AppColors.vitality)
            Text("Keep syncing health data to unlock Vitality Age.")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var ageCard: some View {
        ageCardContent(
            vitality: app.latestScores?.vitalityAge?.years ?? 0,
            delta: app.latestScores?.vitalityAge?.deltaVsChronological ?? 0
        )
    }

    /// Locals are parameters so SwiftUI's opaque `some View` result does not drop them from scope.
    private func ageCardContent(vitality: Double, delta: Double) -> some View {
        let younger = delta < 0
        let deltaLabel = younger
            ? String(format: "%.1f years younger", abs(delta))
            : String(format: "%.1f years older", delta)

        return VStack(spacing: 8) {
            Text("Vitality Age")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", vitality))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.vitality)
            Text("Chronological \(app.settings.chronologicalAge)")
                .font(AppTypography.body)
            Text(deltaLabel)
                .font(AppTypography.headline)
                .foregroundStyle(younger ? Color.green : Color.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var scoresRow: some View {
        VStack(spacing: 12) {
            scoreTile(
                title: "Readiness",
                value: app.latestScores?.readiness?.score.map { "\(Int($0))" } ?? "—",
                detail: app.latestScores?.readiness?.summary,
                color: AppColors.readiness
            )
            scoreTile(
                title: "Effort",
                value: effortValueText,
                detail: app.latestScores?.effort?.summary,
                color: AppColors.effort
            )
            scoreTile(
                title: "Sleep Score",
                value: app.latestScores?.sleepScore?.score.map { "\(Int($0))" } ?? "—",
                detail: app.latestScores?.sleepScore?.summary,
                color: AppColors.sleep
            )
        }
    }

    private var effortValueText: String {
        guard let score = app.latestScores?.effort?.score else { return "—" }
        let max = app.latestScores?.effort?.scaleMax ?? 21
        return String(format: "%.1f / %.0f", score, max)
    }

    private func scoreTile(title: String, value: String, detail: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(color)
            Text(value)
                .font(AppTypography.metricValue)
            if let detail {
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var driversSection: some View {
        if let drivers = app.latestScores?.vitalityAge?.drivers, !drivers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "What helps or hurts", subtitle: "Top drivers of Vitality Age")
                ForEach(drivers) { driver in
                    HStack(alignment: .top) {
                        Image(systemName: (driver.effectYears ?? 0) <= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundStyle((driver.effectYears ?? 0) <= 0 ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(driver.metric.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(AppTypography.headline)
                            if let note = driver.note {
                                Text(note)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let effect = driver.effectYears {
                            Text(String(format: "%+.1f y", effect))
                                .font(AppTypography.caption)
                        }
                    }
                    .padding(12)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    VitalityAgeView()
        .environment(AppEnvironment())
}
