import SwiftUI

// MARK: - Activity Category

/// All available time tracking categories with their visual and scoring properties.
enum ActivityCategory: String, CaseIterable, Identifiable, Codable {
    case revenueGenerating = "Revenue Generating"
    case strategisch = "Strategisch"
    case deepWork = "Deep Work"
    case admin = "Admin"
    case konsum = "Konsum"
    case ablenkung = "Ablenkung"
    case pause = "Pause"
    case training = "Training"
    case schlaf = "Schlaf"
    case beziehung = "Beziehung / Social"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }

    /// Keyboard shortcut key for quick selection (1-9, 0, -)
    var shortcutKey: String {
        switch self {
        case .revenueGenerating: return "1"
        case .strategisch: return "2"
        case .deepWork: return "3"
        case .admin: return "4"
        case .konsum: return "5"
        case .ablenkung: return "6"
        case .pause: return "7"
        case .training: return "8"
        case .schlaf: return "9"
        case .beziehung: return "0"
        case .sonstiges: return "-"
        }
    }

    /// KeyEquivalent for SwiftUI keyboard shortcuts
    var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character(shortcutKey))
    }

    /// Color used in UI and charts
    var color: Color {
        switch self {
        case .revenueGenerating: return .green
        case .strategisch: return .blue
        case .deepWork: return .purple
        case .admin: return .orange
        case .konsum: return .yellow
        case .ablenkung: return .red
        case .pause: return .gray
        case .training: return .mint
        case .schlaf: return .indigo
        case .beziehung: return .pink
        case .sonstiges: return Color(.systemGray)
        }
    }

    /// Productivity weight for Focus Score calculation.
    /// Range: -1.0 (fully unproductive) to +1.0 (fully productive)
    var productivityWeight: Double {
        switch self {
        case .revenueGenerating: return 1.0
        case .deepWork: return 1.0
        case .strategisch: return 0.7
        case .training: return 0.3
        case .admin: return 0.0
        case .pause: return 0.0
        case .schlaf: return 0.0
        case .beziehung: return 0.0
        case .sonstiges: return 0.0
        case .konsum: return -0.5
        case .ablenkung: return -1.0
        }
    }

    /// SF Symbol icon name
    var sfSymbol: String {
        switch self {
        case .revenueGenerating: return "dollarsign.circle.fill"
        case .strategisch: return "map.fill"
        case .deepWork: return "brain.head.profile"
        case .admin: return "tray.full.fill"
        case .konsum: return "play.tv.fill"
        case .ablenkung: return "exclamationmark.triangle.fill"
        case .pause: return "cup.and.saucer.fill"
        case .training: return "figure.run"
        case .schlaf: return "moon.fill"
        case .beziehung: return "person.2.fill"
        case .sonstiges: return "ellipsis.circle.fill"
        }
    }

    /// Whether this category counts as "productive" for streak tracking
    var isProductive: Bool {
        productivityWeight > 0
    }

    /// Suggested category when system was idle
    static var idleSuggestions: [ActivityCategory] {
        [.pause, .schlaf]
    }

    /// Menu bar indicator color based on productivity
    var indicatorColor: Color {
        if productivityWeight > 0.5 { return .green }
        if productivityWeight > 0 { return .blue }
        if productivityWeight == 0 { return .gray }
        if productivityWeight > -0.7 { return .yellow }
        return .red
    }
}
