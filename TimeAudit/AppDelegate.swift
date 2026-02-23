import AppKit
import SwiftUI
import SwiftData

// MARK: - App Delegate

/// Manages the floating panel lifecycle, sleep/wake monitoring, and idle detection.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The floating logging popup panel
    private var loggingPanel: FloatingPanel<AnyView>?

    /// Sleep/wake monitor
    let sleepWakeMonitor = SleepWakeMonitor()

    /// Idle detector
    let idleDetector = IdleDetector()

    /// Shared view models
    let timerVM = TimerViewModel()
    let loggingVM = LoggingViewModel()
    let statsVM = StatisticsViewModel()
    let settingsVM = SettingsViewModel()

    /// SwiftData model container (shared)
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup SwiftData
        do {
            modelContainer = try ModelContainer(for: TimeEntry.self, AppSettings.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Load settings
        if let context = modelContainer?.mainContext {
            settingsVM.load(context: context)
            timerVM.intervalMinutes = settingsVM.intervalMinutes
        }

        // Start timer
        timerVM.start()

        // Start idle detection
        idleDetector.startPolling(interval: 30)

        // Setup sleep/wake monitoring
        sleepWakeMonitor.onWake = { [weak self] in
            self?.timerVM.handleWake()
        }
        sleepWakeMonitor.start()

        // Register global keyboard shortcut (Cmd+Shift+T)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+Shift+T
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 17 {
                DispatchQueue.main.async {
                    self?.showLoggingPanel()
                }
            }
        }

        // Also register local monitor for when app is active
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 17 {
                DispatchQueue.main.async {
                    self?.showLoggingPanel()
                }
                return nil
            }
            return event
        }
    }

    /// Show the floating logging panel
    func showLoggingPanel() {
        guard let container = modelContainer else { return }

        // Check idle state
        loggingVM.setIdleDetected(idleDetector.isIdle)

        // Load recent entries for smart defaults
        let context = container.mainContext
        let descriptor = FetchDescriptor<TimeEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let recent = try? context.fetch(descriptor) {
            loggingVM.loadRecentCategories(from: Array(recent.prefix(10)))
        }

        // Play sound if enabled
        if settingsVM.soundEnabled {
            SoundPlayer.playSystemSound()
        }

        if loggingPanel == nil || !(loggingPanel?.isVisible ?? false) {
            let view = LoggingPopupView(
                loggingVM: loggingVM,
                intervalMinutes: settingsVM.intervalMinutes
            ) { [weak self] in
                self?.onLogSaved()
            }
            .modelContainer(container)

            loggingPanel = FloatingPanel(contentView: AnyView(view))
        }

        loggingPanel?.present()
    }

    /// Called when user saves a log entry
    private func onLogSaved() {
        loggingPanel?.dismiss()
        timerVM.didLog()

        // Refresh statistics
        if let context = modelContainer?.mainContext {
            let descriptor = FetchDescriptor<TimeEntry>()
            if let entries = try? context.fetch(descriptor) {
                statsVM.refresh(entries: entries)
            }
        }
    }

    /// Show the statistics window
    func showStatisticsWindow() {
        guard let container = modelContainer else { return }

        let view = StatisticsView(statsVM: statsVM)
            .modelContainer(container)

        let panel = FloatingPanel(contentView: AnyView(view))
        panel.canDismiss = true
        panel.title = "TimeAudit - Statistiken"
        panel.setContentSize(NSSize(width: 500, height: 480))
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show the settings window
    func showSettingsWindow() {
        guard let container = modelContainer else { return }

        let view = SettingsView(settingsVM: settingsVM)
            .modelContainer(container)

        let panel = FloatingPanel(contentView: AnyView(view))
        panel.canDismiss = true
        panel.title = "TimeAudit - Einstellungen"
        panel.setContentSize(NSSize(width: 420, height: 500))
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerVM.stop()
        idleDetector.stopPolling()
        sleepWakeMonitor.stop()
    }
}
