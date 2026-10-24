import SwiftUI
import UIKit

enum AppTypography {
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let metricValue = Font.system(.title, design: .rounded).weight(.bold)
    static let metricUnit = Font.caption.weight(.medium)

    /// Home styles. Plus Jakarta Sans is registered with `UIAppFonts`.
    /// If a face is missing at render time, the matching system weight is used.
    static var greeting: Font { face("PlusJakartaSans-ExtraBold", size: 27, relativeTo: .title, fallback: .heavy) }
    static var bigValue: Font { face("PlusJakartaSans-Bold", size: 26, relativeTo: .title, fallback: .bold) }
    static var cardLabel: Font { face("PlusJakartaSans-Medium", size: 13, relativeTo: .footnote, fallback: .medium) }
    static var homeCaption: Font { face("PlusJakartaSans-Regular", size: 13, relativeTo: .footnote, fallback: .regular) }
    static var homeTitle: Font { face("PlusJakartaSans-Bold", size: 17, relativeTo: .headline, fallback: .bold) }
    static var rowLabel: Font { face("PlusJakartaSans-Regular", size: 13, relativeTo: .footnote, fallback: .regular) }
    static var rowValue: Font { face("PlusJakartaSans-SemiBold", size: 13, relativeTo: .footnote, fallback: .semibold) }
    static var recommendedHeader: Font { face("PlusJakartaSans-Bold", size: 13, relativeTo: .footnote, fallback: .bold) }
    static var pillLabel: Font { face("PlusJakartaSans-Medium", size: 12, relativeTo: .caption, fallback: .medium) }
    static var pillValue: Font { face("PlusJakartaSans-Bold", size: 17, relativeTo: .headline, fallback: .bold) }
    static var backNote: Font { face("PlusJakartaSans-Regular", size: 11, relativeTo: .caption2, fallback: .regular) }
    static var weeklyTitle: Font { face("PlusJakartaSans-ExtraBold", size: 34, relativeTo: .largeTitle, fallback: .heavy) }
    static var weeklyValue: Font { face("PlusJakartaSans-Bold", size: 18, relativeTo: .title3, fallback: .bold) }
    static var weeklyDelta: Font { face("PlusJakartaSans-SemiBold", size: 11, relativeTo: .caption2, fallback: .semibold) }

    /// Returns the bundled face when UIKit can resolve its PostScript name.
    private static func face(
        _ postScriptName: String,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        fallback: Font.Weight
    ) -> Font {
        if UIFont(name: postScriptName, size: size) != nil {
            return Font.custom(postScriptName, size: size, relativeTo: textStyle)
        }
        return Font.system(size: size, weight: fallback)
    }
}
