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

    init(
        intervalMinutes: Int = 15,
        soundEnabled: Bool = true,
        customCategories: [String] = []
    ) {
        self.intervalMinutes = intervalMinutes
        self.soundEnabled = soundEnabled
        self.customCategories = customCategories
    }

    /// Available interval options
    static let intervalOptions = [15, 30, 60]
}
