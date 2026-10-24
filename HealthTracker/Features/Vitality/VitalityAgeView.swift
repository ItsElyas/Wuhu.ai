import SwiftUI

struct VitalityAgeView: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if shouldShowCollectingCard {
                        collectingCard
                    } else {
                        ageCard
                    }

                    scoresRow
                    driversSection

                    if app.usedLocalFallback {
                        Text("Estimated locally")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2), in: Capsule())
                            .accessibilityLabel("Scores estimated locally")
                    }

                    Text(disclaimerText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Vitality Age")
        }
    }

    private var shouldShowCollectingCard: Bool {
        if app.latestScores?.insufficientData == true {
            return true
        }
        return app.latestScores?.vitalityAge?.years == nil
    }

    private var disclaimerText: String {
        app.latestScores?.disclaimer
            ?? "Estimate for motivation only, not a medical measurement."
    }

    private var vitalityYears: Double {
        app.latestScores?.vitalityAge?.years ?? 0
    }

    private var ageDelta: Double {
        app.latestScores?.vitalityAge?.deltaVsChronological ?? 0
    }

    private var ageDeltaLabel: String {
        if ageDelta < 0 {
            return String(format: "%.1f years younger", Swift.abs(ageDelta))
        }
        return String(format: "%.1f years older", ageDelta)
    }

    private var ageDeltaColor: Color {
        ageDelta < 0 ? .green : .orange
    }

    private var daysWithData: Int {
        app.lastSnapshot?.dataQuality.daysWithData ?? 0
    }

    private var effortValueText: String {
        guard let score = app.latestScores?.effort?.score else {
            return "-"
        }
        let scaleMax = app.latestScores?.effort?.scaleMax ?? 21
        return String(format: "%.1f / %.0f", score, scaleMax)
    }

    private var readinessValueText: String {
        guard let score = app.latestScores?.readiness?.score else {
            return "-"
        }
        return "\(Int(score))"
    }

    private var sleepValueText: String {
        guard let score = app.latestScores?.sleepScore?.score else {
            return "-"
        }
        return "\(Int(score))"
    }

    private var collectingCard: some View {
        VStack(spacing: 8) {
            Text("Collecting data")
                .font(.title2.weight(.semibold))
            Text("\(daysWithData)/\(VitalityConfig.minimumDaysOfData) days")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.vitality)
            Text("Keep syncing health data to unlock Vitality Age.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var ageCard: some View {
        VStack(spacing: 8) {
            Text("Vitality Age")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", vitalityYears))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.vitality)
            Text("Chronological \(app.settings.chronologicalAge)")
                .font(.body)
            Text(ageDeltaLabel)
                .font(.headline)
                .foregroundStyle(ageDeltaColor)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var scoresRow: some View {
        VStack(spacing: 12) {
            scoreTile(
                title: "Readiness",
                value: readinessValueText,
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
                value: sleepValueText,
                detail: app.latestScores?.sleepScore?.summary,
                color: AppColors.sleep
            )
        }
    }

    private func scoreTile(title: String, value: String, detail: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var driversSection: some View {
        if let drivers = app.latestScores?.vitalityAge?.drivers, !drivers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "What helps or hurts", subtitle: "Top drivers of Vitality Age")
                ForEach(Array(drivers.enumerated()), id: \.offset) { _, driver in
                    driverRow(driver)
                }
            }
        }
    }

    private func driverRow(_ driver: ScoreDriver) -> some View {
        let effect = driver.effectYears ?? 0
        let isHelpful = effect <= 0
        return HStack(alignment: .top) {
            Image(systemName: isHelpful ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isHelpful ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.metric.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                if let note = driver.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let effectYears = driver.effectYears {
                Text(String(format: "%+.1f y", effectYears))
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
