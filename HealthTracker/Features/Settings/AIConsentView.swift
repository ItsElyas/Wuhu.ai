import SwiftUI

struct AIConsentView: View {
    @Environment(AppEnvironment.self) private var app
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI scoring (optional)")
                    .font(AppTypography.title)
                Text("HealthTracker can send a compact summary of your health stats (not raw samples, names, or device IDs) to an AI provider to compute Vitality Age, Readiness, Effort, and Sleep Score.")
                    .font(AppTypography.body)
                Text("You can turn this off anytime in Settings. When off, scores are estimated on device.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                Toggle("Allow AI scoring", isOn: Binding(
                    get: { app.settings.aiScoringConsent },
                    set: { app.settings.aiScoringConsent = $0 }
                ))

                Spacer()

                Button {
                    app.settings.aiConsentShown = true
                    app.refreshProvider()
                    isPresented = false
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AIConsentView(isPresented: .constant(true))
        .environment(AppEnvironment())
}
