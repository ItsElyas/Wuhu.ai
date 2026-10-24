import SwiftUI

struct SkeletonView: View {
    var height: CGFloat = 88

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.gray.opacity(0.18))
            .frame(height: height)
            .redacted(reason: .placeholder)
            .accessibilityLabel("Loading")
    }
}

#Preview {
    SkeletonView()
        .padding()
}
