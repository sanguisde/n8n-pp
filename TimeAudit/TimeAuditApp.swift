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
                onLogNow: { appDelegate.showLoggingPanel() },
                onOpenStatistics: { appDelegate.showStatisticsWindow() },
                onOpenSettings: { appDelegate.showSettingsWindow() }
            )
            .modelContainer(for: [TimeEntry.self, AppSettings.self])
            .onAppear {
                observeTimerPopup()
            }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    /// Menu bar icon: clock with colored dot indicating last category
    private var menuBarLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))

            // Colored indicator dot for last logged category
            Circle()
                .fill(lastCategoryColor)
                .frame(width: 6, height: 6)
        }
    }

    /// Color based on the last logged category's productivity
    private var lastCategoryColor: Color {
        // Read from UserDefaults for quick access (set by LoggingViewModel on save)
        if let lastCat = UserDefaults.standard.string(forKey: "lastCategory"),
           let category = ActivityCategory(rawValue: lastCat) {
            return category.indicatorColor
        }
        return .gray
    }

    /// Observe timer to show popup when needed
    private func observeTimerPopup() {
        // Check periodically if popup should be shown
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
