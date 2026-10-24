import CoreGraphics

/// Layout measurements from `docs/UI_SPEC.md`, tuned for a 402 pt-wide iPhone 16 Pro.
enum LayoutMetrics {
    static let referenceWidth: CGFloat = 402
    static let horizontalMargin: CGFloat = 20
    static let sectionSpacing: CGFloat = 14
    static let greetingTop: CGFloat = 8
    static let greetingBottom: CGFloat = 16
    static let cardGap: CGFloat = 13
    static let topCardHeight: CGFloat = 101
    static let cardRadius: CGFloat = 28
    static let cardPadding: CGFloat = 15
    static let wearRadius: CGFloat = 30
    static let wearPadding: CGFloat = 17
    static let wearHeight: CGFloat = 238
    static let figureWidth: CGFloat = 68
    static let figureHeight: CGFloat = 128
    static let figureLeadingGap: CGFloat = 9
    static let figureTrailingGap: CGFloat = 8
    static let pillColumnWidth: CGFloat = 120
    static let pillRadius: CGFloat = 20
    static let pillGap: CGFloat = 7
    static let navHeight: CGFloat = 49
    static let navIconLeading: CGFloat = 17
    static let navTrailingInset: CGFloat = 24
    static let fabSize: CGFloat = 48
    static let fabGap: CGFloat = 10
    static let ringDiameter: CGFloat = 48
    static let ringStroke: CGFloat = 5
    static let ringGap: CGFloat = 12
    static let legendDot: CGFloat = 8
    static let avatarSize: CGFloat = 36
    static let bottomScrollInset: CGFloat = 24
}
