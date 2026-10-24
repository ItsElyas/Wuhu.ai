import Charts
import SwiftUI

struct WeeklyRunningProgressView: View {
    var display: RunningWeekDisplay
    var intakeLine: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let intakeLine {
                Text(intakeLine)
                    .font(AppTypography.homeCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            statsRow
            consistencyCard
            paceAndHighlights
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(display.stats) { metric in
                WeeklyMetricCard(metric: metric)
            }
        }
    }

    private var consistencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "list.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x3B82F6))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Run Consistency")
                        .font(AppTypography.homeTitle)
                        .foregroundStyle(AppColors.ink)
                    Text(display.distanceNote ?? "Miles per day this week")
                        .font(AppTypography.backNote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer(minLength: 8)
                consistencyRing
            }
            Text("Miles")
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
            consistencyChart
        }
        .padding(16)
        .glassCard(radius: 26)
    }

    private var consistencyRing: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppColors.ringTrack, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(display.runsCompleted) / CGFloat(display.runsPossible))
                    .stroke(Color(hex: 0x2FCB7A), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(display.runsCompleted) / \(display.runsPossible)")
                        .font(AppTypography.homeTitle)
                        .foregroundStyle(AppColors.ink)
                    Text("\(display.consistencyPercent)%")
                        .font(AppTypography.weeklyDelta)
                        .foregroundStyle(Color(hex: 0x1FA971))
                }
                Text("Runs this week")
                    .font(AppTypography.backNote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(display.runsCompleted) of \(display.runsPossible) runs this week, \(display.consistencyPercent) percent")
    }

    private var consistencyChart: some View {
        Chart(display.days) { day in
            BarMark(
                x: .value("Day", day.weekday),
                y: .value("Miles", day.barHeight),
                width: .fixed(22)
            )
            .foregroundStyle(day.miles == nil ? Color(hex: 0xC8CDD8) : Color(hex: 0x2FCB7A))
            .cornerRadius(6)
            .annotation(position: .top, spacing: 4) {
                Text(day.label)
                    .font(AppTypography.weeklyDelta)
                    .foregroundStyle(day.miles == nil ? AppColors.textTertiary : AppColors.ink)
            }
        }
        .chartYScale(domain: 0...milesAxisTop)
        .chartXScale(domain: display.days.map(\.weekday), type: .category)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 2, 4, 6]) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: display.days.map(\.weekday)) { value in
                AxisValueLabel {
                    if let name = value.as(String.self),
                       let day = display.days.first(where: { $0.weekday == name }) {
                        VStack(spacing: 0) {
                            Text(day.weekday)
                                .font(AppTypography.weeklyDelta)
                                .foregroundStyle(AppColors.ink)
                            Text(day.date)
                                .font(AppTypography.backNote)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Miles by day this week")
    }

    private var paceAndHighlights: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                paceCard
                highlights.frame(width: 148)
            }
            VStack(alignment: .leading, spacing: 10) {
                paceCard
                highlights
            }
        }
    }

    private var paceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x7A5AF8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pace & Heart Rate")
                        .font(AppTypography.homeTitle)
                        .foregroundStyle(AppColors.ink)
                    Text("Pace and heart rate during your runs")
                        .font(AppTypography.backNote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            HStack(spacing: 12) {
                legendDot(Color(hex: 0xF071A5), "Heart Rate (bpm)")
                legendDot(Color(hex: 0x3B82F6), "Pace (min/mi)")
            }
            paceChart
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var milesAxisTop: Double {
        let peak = display.days.map(\.barHeight).max() ?? 1
        return max(7.4, (peak + 1).rounded(.up))
    }

    private var paceChart: some View {
        Group {
            if display.paceSamples.count < 2 {
                Text("Pace and heart rate show after two runs that include distance and heart rate.")
                    .font(AppTypography.homeCaption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            } else {
                paceMarks
            }
        }
    }

    private var paceMarks: some View {
        Chart {
            ForEach(display.paceSamples) { sample in
                AreaMark(
                    x: .value("Mile", sample.mile),
                    y: .value("Heart rate", sample.heartRate),
                    series: .value("Series", "Heart")
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xF071A5).opacity(0.45), Color(hex: 0xF071A5).opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Mile", sample.mile),
                    y: .value("Heart rate", sample.heartRate),
                    series: .value("Series", "Heart")
                )
                .foregroundStyle(Color(hex: 0xF071A5))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Mile", sample.mile),
                    y: .value("Pace", RunningWeekBuilder.paceChartY(sample.paceMinutes)),
                    series: .value("Series", "Pace")
                )
                .foregroundStyle(Color(hex: 0x3B82F6))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 40...200)
        .chartXScale(domain: 0...paceAxisMax)
        .chartYAxis {
            AxisMarks(position: .leading, values: [40, 80, 120, 160, 200]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bpm = value.as(Double.self) {
                        Text("\(Int(bpm))")
                            .font(AppTypography.backNote)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            AxisMarks(position: .trailing, values: [40, 80, 120, 160, 200]) { value in
                AxisValueLabel {
                    if let bpm = value.as(Double.self) {
                        Text(paceAxisLabel(bpm))
                            .font(AppTypography.backNote)
                            .foregroundStyle(Color(hex: 0x3B82F6))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: paceTicks) { value in
                AxisValueLabel {
                    if let mile = value.as(Double.self) {
                        Text("\(Int(mile))")
                            .font(AppTypography.backNote)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        }
        .chartXAxisLabel {
            Text("Distance (miles)")
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(height: 190)
        .accessibilityLabel("Heart rate and pace across five miles")
    }

    private var paceTicks: [Double] {
        let step = max(1, (paceAxisMax / 5).rounded(.up))
        return Array(stride(from: 0, through: paceAxisMax, by: step))
    }

    private var paceAxisMax: Double {
        let peak = display.paceSamples.map(\.mile).max() ?? 5
        return max(5, peak.rounded(.up))
    }

    private func paceAxisLabel(_ mappedHeartRate: Double) -> String {
        let minutes = 6 + ((200 - mappedHeartRate) / 160) * 8
        let whole = Int(minutes.rounded())
        return String(format: "%d:00", whole)
    }

    private var highlights: some View {
        VStack(spacing: 8) {
            ForEach(display.highlights) { item in
                highlightCard(item)
            }
        }
    }

    private func highlightCard(_ item: RunningHighlight) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: item.tintHex))
                Text(item.title)
                    .font(AppTypography.rowValue)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(item.detail)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
            Text(item.value)
                .font(AppTypography.weeklyValue)
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(item.note)
                .font(AppTypography.backNote)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 20, shadowed: false)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Running") {
    ScrollView {
        WeeklyRunningProgressView(display: RunningWeeklyFixture.display)
            .padding()
    }
    .background(MeshBackground())
}
