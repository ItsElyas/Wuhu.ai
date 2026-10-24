import SwiftUI
import SwiftData

/// One run segment: distance, time (mm:ss), optional average HR; pace is calculated.
struct RunSegmentCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var segment: HubRunSegment

    @State private var milesText = ""
    @State private var timeText = ""
    @State private var heartRateText = ""

    private var milesInvalid: Bool {
        !milesText.isEmpty && HubFormat.parseNumber(milesText, in: HubFormat.milesRange) == nil
    }
    private var timeInvalid: Bool {
        !timeText.isEmpty && HubFormat.parseDuration(timeText) == nil
    }
    private var heartRateInvalid: Bool {
        !heartRateText.isEmpty && HubFormat.parseNumber(heartRateText, in: HubFormat.heartRateRange) == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.label)
                        .font(AppTypography.cardLabel)
                        .foregroundStyle(AppColors.ink)
                    if let target = segment.target {
                        Text("Target: \(target)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                Button {
                    segment.isCompleted.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: segment.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(segment.isCompleted ? AppColors.accent : AppColors.textSecondary)
                }
                .accessibilityLabel(segment.isCompleted ? "\(segment.label) done" : "Mark \(segment.label) done")
            }

            HStack(spacing: 8) {
                field("MILES", "0.00", $milesText, .decimalPad, invalid: milesInvalid, label: "Distance in miles")
                field("TIME", "mm:ss", $timeText, .numbersAndPunctuation, invalid: timeInvalid, label: "Time, minutes and seconds")
                field("AVG HR", "bpm", $heartRateText, .numberPad, invalid: heartRateInvalid, label: "Average heart rate")
            }

            HStack {
                Text("Pace")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(segment.paceSecondsPerMile.map(HubFormat.pace) ?? "Enter miles and time")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(segment.paceSecondsPerMile == nil ? AppColors.textSecondary : AppColors.ink)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(LayoutMetrics.cardPadding)
        .glassCard(radius: 16, shadowed: false)
        .onAppear {
            milesText = segment.distanceMiles.map { String(format: "%.2f", $0) } ?? ""
            timeText = segment.durationSeconds.map(HubFormat.duration) ?? ""
            heartRateText = segment.averageHeartRate.map { String(Int($0)) } ?? ""
        }
        .onChange(of: milesText) { _, text in
            save(text, parse: { HubFormat.parseNumber($0, in: HubFormat.milesRange) }) { segment.distanceMiles = $0 }
        }
        .onChange(of: timeText) { _, text in
            save(text, parse: HubFormat.parseDuration) { segment.durationSeconds = $0 }
        }
        .onChange(of: heartRateText) { _, text in
            save(text, parse: { HubFormat.parseNumber($0, in: HubFormat.heartRateRange) }) { segment.averageHeartRate = $0 }
        }
    }

    /// Clears on empty, saves on valid, ignores invalid (field turns red).
    private func save(_ text: String, parse: (String) -> Double?, assign: (Double?) -> Void) {
        if text.isEmpty {
            assign(nil)
        } else if let value = parse(text) {
            assign(value)
        } else {
            return
        }
        try? modelContext.save()
    }

    private func field(
        _ title: String,
        _ placeholder: String,
        _ text: Binding<String>,
        _ keyboard: UIKeyboardType,
        invalid: Bool,
        label: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .modifier(HubFieldStyle(invalid: invalid))
                .accessibilityLabel(label)
        }
    }
}
