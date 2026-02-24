import SwiftUI

// MARK: - Activity Category

/// The three core time tracking categories.
/// Stored as Int in SwiftData for consistency regardless of IdentityMode.
enum ActivityCategory: Int, CaseIterable, Identifiable, Codable {
    case productive = 1    // Umsatzgenerierend
    case neutral = 2       // Neutral
    case harmful = 3       // Umsatzschaedigend

    var id: Int { rawValue }

    /// Default display name (Standard mode)
    var displayName: String {
        switch self {
        case .productive: return "Umsatzgenerierend"
        case .neutral: return "Neutral"
        case .harmful: return "Umsatzschaedigend"
        }
    }

    /// Keyboard shortcut key for quick selection
    var shortcutKey: String {
        switch self {
        case .productive: return "1"
        case .neutral: return "2"
        case .harmful: return "3"
        }
    }

    /// KeyEquivalent for SwiftUI keyboard shortcuts
    var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character(shortcutKey))
    }

    /// Color used in UI and charts
    var color: Color {
        switch self {
        case .productive: return .green
        case .neutral: return .gray
        case .harmful: return .red
        }
    }

    /// Productivity weight for Focus Score calculation.
    /// Range: -1.0 (harmful) to +1.0 (productive)
    var productivityWeight: Double {
        switch self {
        case .productive: return 1.0
        case .neutral: return 0.0
        case .harmful: return -1.0
        }
    }

    /// SF Symbol icon name
    var sfSymbol: String {
        switch self {
        case .productive: return "chart.line.uptrend.xyaxis"
        case .neutral: return "minus.circle.fill"
        case .harmful: return "exclamationmark.triangle.fill"
        }
    }

    /// Whether this category counts as productive for streak tracking
    var isProductive: Bool {
        self == .productive
    }

    /// Menu bar indicator color
    var indicatorColor: Color {
        color
    }

    /// Initialize from Int value
    static func from(_ value: Int) -> ActivityCategory? {
        ActivityCategory(rawValue: value)
    }
}
