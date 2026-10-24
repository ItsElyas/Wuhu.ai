import SwiftUI

struct ChatFAB: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "bubble.left")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: LayoutMetrics.fabSize, height: LayoutMetrics.fabSize)
                .background(AppColors.fabFill, in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Open health chat")
    }
}

#Preview {
    ChatFAB(onTap: {})
        .padding()
        .background(MeshBackground())
}
