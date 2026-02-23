import AppKit
import SwiftUI
import SwiftData

// MARK: - App Delegate

/// Manages the floating panel lifecycle, sleep/wake monitoring, and idle detection.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The floating logging popup panel
    private var loggingPanel: FloatingPanel<AnyView>?

    /// Always-on-top desktop widget for quick logging
    private var widgetPanel: FloatingWidget?

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

        // Show desktop widget if enabled
        if settingsVM.widgetEnabled {
            showWidget()
        }

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

    /// Reusable windows so we don't create duplicates
    private var statisticsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    /// Show the statistics window
    func showStatisticsWindow() {
        guard let container = modelContainer else { return }

        if let existing = statisticsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = StatisticsView(statsVM: statsVM)
            .modelContainer(container)
            .preferredColorScheme(.dark)

        let window = createStandardWindow(
            title: "TimeAudit - Statistiken",
            size: NSSize(width: 500, height: 480),
            content: view
        )
        statisticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show the settings window
    func showSettingsWindow() {
        guard let container = modelContainer else { return }

        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(settingsVM: settingsVM)
            .modelContainer(container)
            .preferredColorScheme(.dark)

        let window = createStandardWindow(
            title: "TimeAudit - Einstellungen",
            size: NSSize(width: 420, height: 500),
            content: view
        )
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Create a normal, interactive NSWindow with opaque background for standard views
    private func createStandardWindow(title: String, size: NSSize, content: some View) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content)
        window.center()
        return window
    }

    // MARK: - Desktop Widget

    /// Show the always-on-top desktop widget
    func showWidget() {
        guard let container = modelContainer else { return }

        if let existing = widgetPanel {
            existing.present()
            return
        }

        let view = FloatingWidgetView(
            timerVM: timerVM,
            statsVM: statsVM,
            settingsVM: settingsVM
        )
        .modelContainer(container)

        widgetPanel = FloatingWidget(contentView: view)
        widgetPanel?.present()
    }

    /// Hide the desktop widget
    func hideWidget() {
        widgetPanel?.hideWidget()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerVM.stop()
        idleDetector.stopPolling()
        sleepWakeMonitor.stop()
    }
}
