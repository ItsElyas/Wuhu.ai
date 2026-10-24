import SwiftUI

/// Vitality tab (replaces legacy VitalityAgeView.swift).
struct VitalityAgeScreen: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if showCollecting {
                        collectingCard
                    } else {
                        mainAgeCard
                    }
                    scoreTiles
                    driversList
                    if app.usedLocalFallback {
                        Text("Estimated locally")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2), in: Capsule())
                    }
                    Text(app.latestScores?.disclaimer ?? "Estimate for motivation only, not a medical measurement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Vitality Age")
        }
    }

    private var showCollecting: Bool {
        app.latestScores?.insufficientData == true || app.latestScores?.vitalityAge?.years == nil
    }

    private var vitalityYears: Double {
        app.latestScores?.vitalityAge?.years ?? 0
    }

    private var ageDelta: Double {
        app.latestScores?.vitalityAge?.deltaVsChronological ?? 0
    }

    private var daysWithData: Int {
        app.lastSnapshot?.dataQuality.daysWithData ?? 0
    }

    private var collectingCard: some View {
        VStack(spacing: 8) {
            Text("Collecting data")
                .font(.title2.weight(.semibold))
            Text("\(daysWithData)/\(VitalityConfig.minimumDaysOfData) days")
                .font(.title.weight(.bold))
                .foregroundStyle(AppColors.vitality)
            Text("Keep syncing health data to unlock Vitality Age.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var mainAgeCard: some View {
        VStack(spacing: 8) {
            Text("Vitality Age")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", vitalityYears))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.vitality)
            Text("Chronological \(app.settings.chronologicalAge)")
            Text(VitalityAgePresentation.deltaLabel(delta: ageDelta))
                .font(.headline)
                .foregroundStyle(VitalityAgePresentation.deltaColor(delta: ageDelta))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var scoreTiles: some View {
        VStack(spacing: 12) {
            scoreRow(
                title: "Readiness",
                value: VitalityAgePresentation.scoreText(app.latestScores?.readiness?.score),
                detail: app.latestScores?.readiness?.summary,
                color: AppColors.readiness
            )
            scoreRow(
                title: "Effort",
                value: VitalityAgePresentation.effortText(
                    score: app.latestScores?.effort?.score,
                    scaleMax: app.latestScores?.effort?.scaleMax
                ),
                detail: app.latestScores?.effort?.summary,
                color: AppColors.effort
            )
            scoreRow(
                title: "Sleep Score",
                value: VitalityAgePresentation.scoreText(app.latestScores?.sleepScore?.score),
                detail: app.latestScores?.sleepScore?.summary,
                color: AppColors.sleep
            )
        }
    }

    private func scoreRow(title: String, value: String, detail: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(color)
            Text(value).font(.title2.weight(.bold))
            if let detail {
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var driversList: some View {
        if let drivers = app.latestScores?.vitalityAge?.drivers, !drivers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "What helps or hurts", subtitle: "Top drivers of Vitality Age")
                ForEach(Array(drivers.enumerated()), id: \.offset) { _, driver in
                    HStack(alignment: .top) {
                        Text(driver.metric.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.headline)
                        Spacer()
                        if let effect = driver.effectYears {
                            Text(String(format: "%+.1f y", effect))
                                .font(.caption)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
