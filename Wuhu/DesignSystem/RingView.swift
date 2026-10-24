import SwiftUI

struct RingView: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = AppColors.steps

    private var clamped: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: clamped)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

#Preview {
    RingView(progress: 0.62)
        .frame(width: 80, height: 80)
}
