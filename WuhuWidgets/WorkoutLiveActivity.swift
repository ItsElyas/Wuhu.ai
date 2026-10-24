import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen banner and Dynamic Island for an active workout. The timer uses
/// `Text(timerInterval:)`, which the system renders live without the app running.
struct WorkoutLiveActivity: Widget {
    private let accent = Color(red: 0xE1 / 255, green: 0x45 / 255, blue: 0x3F / 255)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(WorkoutDeepLink.url(for: context.attributes.sessionID))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.symbol)
                        .font(.title2)
                        .foregroundStyle(accent)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(context.state.startedAt)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                        Text(context.state.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: context.attributes.symbol).foregroundStyle(accent)
            } compactTrailing: {
                timer(context.state.startedAt)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: context.attributes.symbol).foregroundStyle(accent)
            }
            .widgetURL(WorkoutDeepLink.url(for: context.attributes.sessionID))
        }
    }

    private func lockScreen(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: context.attributes.symbol)
                .font(.title)
                .foregroundStyle(accent)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Workout in progress")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.state.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            timer(context.state.startedAt)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: 100, alignment: .trailing)
        }
        .padding(16)
    }

    private func timer(_ start: Date) -> Text {
        Text(timerInterval: start...Date.distantFuture, countsDown: false)
    }
}
