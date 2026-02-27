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

    /// Whether the desktop widget is visible
    var widgetEnabled: Bool

    /// Identity mode: "standard" or "faith"
    var identityModeRaw: String

    /// Daily goal in minutes for Category 1 (productive)
    var dailyGoalMinutes: Int

    /// Whether to use adaptive goal (7-day avg + 10%) instead of manual
    var useAdaptiveGoal: Bool

    init(
        intervalMinutes: Int = 15,
        soundEnabled: Bool = true,
        widgetEnabled: Bool = true,
        identityModeRaw: String = "standard",
        dailyGoalMinutes: Int = 240,
        useAdaptiveGoal: Bool = false
    ) {
        self.intervalMinutes = intervalMinutes
        self.soundEnabled = soundEnabled
        self.widgetEnabled = widgetEnabled
        self.identityModeRaw = identityModeRaw
        self.dailyGoalMinutes = dailyGoalMinutes
        self.useAdaptiveGoal = useAdaptiveGoal
    }

    /// Available interval options
    static let intervalOptions = [15, 30, 60]

    /// Available daily goal options in hours
    static let dailyGoalHourOptions = [1, 2, 3, 4, 5, 6, 7, 8]
}
