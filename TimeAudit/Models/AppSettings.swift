import Foundation
import SwiftData

// MARK: - App Settings Model

/// Persisted application settings.
@Model
final class AppSettings {
    /// Timer interval in minutes (15, 30, or 60)
    var intervalMinutes: Int

    /// Whether to play a sound on popup
    var soundEnabled: Bool

    /// Custom category names (empty = use defaults)
    var customCategories: [String]

    /// Whether the desktop widget is visible
    var widgetEnabled: Bool

    init(
        intervalMinutes: Int = 15,
        soundEnabled: Bool = true,
        customCategories: [String] = [],
        widgetEnabled: Bool = true
    ) {
        self.intervalMinutes = intervalMinutes
        self.soundEnabled = soundEnabled
        self.customCategories = customCategories
        self.widgetEnabled = widgetEnabled
    }

    /// Available interval options
    static let intervalOptions = [15, 30, 60]
}
