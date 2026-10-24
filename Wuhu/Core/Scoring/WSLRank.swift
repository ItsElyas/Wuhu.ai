import Foundation

/// WSL ranks, highest to lowest.
///
/// Ranking is not computed. `placeholder` is the fixed tier shown on the WSL Score card.
enum WSLRank: String, CaseIterable, Sendable {
    case bron = "Bron"
    case bronLite = "BronLite"
    case htp = "HTP"
    case mtp = "MTP"
    case ltp = "LTP"
    case subPlayer = "Sub-Player"

    /// Fixed on-screen rank until a ranking rule exists.
    static let placeholder: WSLRank = .bron

    var displayName: String {
        switch self {
        case .bron: return "Bron"
        case .bronLite: return "BronLite"
        case .htp: return "HTP"
        case .mtp: return "MTP"
        case .ltp: return "LTP"
        case .subPlayer: return "Sub-Player"
        }
    }
}
