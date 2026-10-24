import SwiftUI

enum AppTypography {
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let metricValue = Font.system(.title, design: .rounded).weight(.bold)
    static let metricUnit = Font.caption.weight(.medium)
}
