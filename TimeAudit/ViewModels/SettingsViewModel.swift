import SwiftUI
import SwiftData
import ServiceManagement

// MARK: - Settings ViewModel

/// Manages app settings: interval, sound, launch at login, identity mode, daily goal.
@Observable
final class SettingsViewModel {
    /// Timer interval in minutes
    var intervalMinutes: Int = 15

    /// Whether notification sound is enabled
    var soundEnabled: Bool = true

    /// Whether the app should launch at login
    var launchAtLogin: Bool = false

    /// Whether the desktop widget is visible
    var widgetEnabled: Bool = true

    /// Identity mode (standard or faith)
    var identityMode: IdentityMode = .standard

    /// Daily goal in minutes for productive blocks
    var dailyGoalMinutes: Int = 240

    /// Whether to use adaptive goal calculation
    var useAdaptiveGoal: Bool = false

    /// Load settings from SwiftData
    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            intervalMinutes = settings.intervalMinutes
            soundEnabled = settings.soundEnabled
            widgetEnabled = settings.widgetEnabled
            identityMode = IdentityMode(rawValue: settings.identityModeRaw) ?? .standard
            dailyGoalMinutes = settings.dailyGoalMinutes
            useAdaptiveGoal = settings.useAdaptiveGoal
        }

        // Read launch at login status from SMAppService
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    /// Save settings to SwiftData
    func save(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        let settings: AppSettings

        if let existing = try? context.fetch(descriptor).first {
            settings = existing
        } else {
            settings = AppSettings()
            context.insert(settings)
        }

        settings.intervalMinutes = intervalMinutes
        settings.soundEnabled = soundEnabled
        settings.widgetEnabled = widgetEnabled
        settings.identityModeRaw = identityMode.rawValue
        settings.dailyGoalMinutes = dailyGoalMinutes
        settings.useAdaptiveGoal = useAdaptiveGoal
    }

    /// Toggle launch at login
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login toggle failed: \(error)")
                launchAtLogin.toggle()
            }
        }
    }

    /// Available interval options
    var intervalOptions: [Int] { AppSettings.intervalOptions }

    /// Daily goal in hours (for UI display)
    var dailyGoalHours: Int {
        get { dailyGoalMinutes / 60 }
        set { dailyGoalMinutes = newValue * 60 }
    }
}
