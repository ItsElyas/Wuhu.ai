import SwiftUI

/// Floating "workout in progress" bubble shown over the app while the logger is minimized.
/// Drag to move; it snaps to the nearest side and remembers its position. Tap to reopen.
struct ActiveWorkoutBubble: View {
    let session: HubSession
    var onOpen: () -> Void

    @AppStorage("workoutBubbleOnLeft") private var onLeft = false
    /// Vertical position as a fraction of the available height (0 = top, 1 = bottom).
    @AppStorage("workoutBubbleY") private var yFraction = 0.72
    @GestureState private var dragOffset: CGSize = .zero

    private let edgeInset: CGFloat = 12
    private let size = CGSize(width: 168, height: 64)

    var body: some View {
        GeometryReader { proxy in
            let bounds = proxy.size
            let x = onLeft ? edgeInset + size.width / 2 : bounds.width - edgeInset - size.width / 2
            let minY = size.height / 2 + edgeInset
            let maxY = max(minY, bounds.height - size.height / 2 - edgeInset)
            let y = min(maxY, max(minY, yFraction * bounds.height))

            bubble
                .position(x: x + dragOffset.width, y: y + dragOffset.height)
                .gesture(
                    DragGesture(minimumDistance: 6)
                        .updating($dragOffset) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            let finalX = x + value.translation.width
                            let finalY = min(maxY, max(minY, y + value.translation.height))
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                onLeft = finalX < bounds.width / 2
                                yFraction = bounds.height > 0 ? finalY / bounds.height : yFraction
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: dragOffset == .zero)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var bubble: some View {
        Button(action: onOpen) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(AppColors.accent)
                    Image(systemName: session.kind.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(HubFormat.duration(max(0, context.date.timeIntervalSince(session.startedAt))))
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(AppColors.ink)
                    }
                    Text(WorkoutLiveActivityController.detail(for: session))
                        .font(.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(width: size.width, height: size.height)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(AppColors.cardStroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.kind.title) workout in progress")
        .accessibilityHint("Opens the workout logger")
    }
}
