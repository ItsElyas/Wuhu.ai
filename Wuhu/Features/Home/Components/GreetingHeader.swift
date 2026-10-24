import SwiftUI

struct GreetingHeader: View {
    var copy: GreetingCopy

    var body: some View {
        (
            Text(copy.nameLine)
            + Text("\n")
            + Text(copy.continuation)
            + Text(copy.accent ?? "").foregroundStyle(AppColors.accent)
            + Text(copy.suffix)
        )
        .font(AppTypography.greeting)
        .foregroundStyle(AppColors.ink)
        .tracking(-0.5)
        .lineSpacing(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(copy.spoken)
    }
}

#Preview("Reference") {
    GreetingHeader(copy: GreetingCopy.make(firstName: "Elyas", plan: HomeFixture.reference.plan))
        .padding()
        .background(MeshBackground())
}

#Preview("No plan") {
    GreetingHeader(copy: GreetingCopy.make(firstName: nil, plan: nil))
        .padding()
}

#Preview("Large type") {
    GreetingHeader(copy: GreetingCopy.make(firstName: "Elyas", plan: HomeFixture.reference.plan))
        .padding()
        .dynamicTypeSize(.accessibility2)
}
