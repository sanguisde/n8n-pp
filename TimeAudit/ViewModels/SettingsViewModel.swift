import SwiftUI
import SwiftData
import ServiceManagement

// MARK: - Settings ViewModel

/// Manages app settings: interval, sound, launch at login.
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

    /// Load settings from SwiftData
    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            intervalMinutes = settings.intervalMinutes
            soundEnabled = settings.soundEnabled
            widgetEnabled = settings.widgetEnabled
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
}
