import SwiftUI
import SwiftData
import Combine

// MARK: - TimeAudit App

/// Main entry point for the TimeAudit menu bar application.
/// Uses MenuBarExtra for the menu bar integration and SwiftData for persistence.
@main
struct TimeAuditApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Track timer state to trigger popup
    @State private var popupCancellable: AnyCancellable?

    var body: some Scene {
        // Menu bar popover (main UI)
        MenuBarExtra {
            MenuBarView(
                statsVM: appDelegate.statsVM,
                timerVM: appDelegate.timerVM,
                identityProvider: appDelegate.identityProvider,
                settingsVM: appDelegate.settingsVM,
                gameVM: appDelegate.gameVM,
                onLogNow: { appDelegate.showLoggingPanel() },
                onOpenStatistics: { appDelegate.showStatisticsWindow() },
                onOpenSettings: { appDelegate.showSettingsWindow() }
            )
            .modelContainer(for: [TimeEntry.self, AppSettings.self, PlayerProfile.self, Achievement.self])
            .onAppear {
                observeTimerPopup()
            }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    /// Menu bar icon: garden icon with colored dot indicating health
    private var menuBarLabel: some View {
        HStack(spacing: 3) {
            GardenMenuBarIcon(score: appDelegate.statsVM.todayFocusScore)

            // Colored indicator dot for last logged category
            Circle()
                .fill(lastCategoryColor)
                .frame(width: 6, height: 6)
        }
    }

    /// Color based on the last logged category
    private var lastCategoryColor: Color {
        let lastValue = UserDefaults.standard.integer(forKey: "lastCategoryValue")
        if let category = ActivityCategory(rawValue: lastValue) {
            return category.indicatorColor
        }
        return .gray
    }

    /// Observe timer to show popup when needed
    private func observeTimerPopup() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if appDelegate.timerVM.shouldShowPopup {
                appDelegate.timerVM.shouldShowPopup = false
                DispatchQueue.main.async {
                    appDelegate.showLoggingPanel()
                }
            }

            // Re-reminder sound
            if appDelegate.timerVM.needsReReminder {
                appDelegate.timerVM.needsReReminder = false
                if appDelegate.settingsVM.soundEnabled {
                    SoundPlayer.playSystemSound()
                }
                DispatchQueue.main.async {
                    appDelegate.showLoggingPanel()
                }
            }
        }
    }
}
