import AppKit
import SwiftUI
import SwiftData

// MARK: - App Delegate

/// Manages the floating panel lifecycle, sleep/wake monitoring, idle detection,
/// and the IdentityMode/Intervention systems.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The floating logging popup panel
    private var loggingPanel: FloatingPanel<AnyView>?

    /// The intervention popup panel
    private var interventionPanel: FloatingPanel<AnyView>?

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
    let interventionVM = InterventionViewModel()

    /// Identity provider for mode-dependent strings
    let identityProvider = IdentityProvider()

    /// RPG game state (XP, gold, level, achievements)
    let gameVM = GameViewModel()

    /// SwiftData model container (shared)
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup SwiftData – on schema migration failure, wipe the store and start fresh
        modelContainer = Self.makeModelContainer()

        // Load settings
        if let context = modelContainer?.mainContext {
            settingsVM.load(context: context)
            timerVM.intervalMinutes = settingsVM.intervalMinutes
            identityProvider.mode = settingsVM.identityMode

            // Load intervention state from recent entries
            let descriptor = FetchDescriptor<TimeEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let entries = try? context.fetch(descriptor) {
                interventionVM.loadFromEntries(entries)
                statsVM.refresh(entries: entries)
            }

            // Initialize RPG system (creates PlayerProfile + achievements if needed)
            gameVM.initializeIfNeeded(context: context)
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

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([TimeEntry.self, AppSettings.self, PlayerProfile.self, Achievement.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Migration failed (e.g. breaking schema change) – delete old store and recreate
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for ext in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(
                    at: storeURL.deletingPathExtension().appendingPathExtension("store\(ext)")
                )
            }
            do {
                return try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }

    /// Show the floating logging panel (or intervention if triggered)
    func showLoggingPanel() {
        guard let container = modelContainer else { return }

        // Check if intervention should be shown instead
        if interventionVM.shouldShowIntervention {
            showInterventionPanel()
            return
        }

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

    /// Show the intervention popup
    private func showInterventionPanel() {
        guard let container = modelContainer else { return }

        if settingsVM.soundEnabled {
            SoundPlayer.playSystemSound()
        }

        if interventionPanel == nil || !(interventionPanel?.isVisible ?? false) {
            let view = InterventionView(
                interventionVM: interventionVM,
                identityProvider: identityProvider
            ) { [weak self] in
                self?.interventionPanel?.dismiss()
                // After dismissing intervention, show normal logging panel
                self?.showLoggingPanel()
            }
            .modelContainer(container)

            interventionPanel = FloatingPanel(contentView: AnyView(view))
        }

        interventionPanel?.present()
    }

    /// Called when user saves a log entry
    private func onLogSaved() {
        loggingPanel?.dismiss()
        timerVM.didLog()

        // Track for intervention logic
        if let context = modelContainer?.mainContext {
            let descriptor = FetchDescriptor<TimeEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let entries = try? context.fetch(descriptor) {
                // Update intervention tracking + RPG engine
                if let lastEntry = entries.first, let cat = lastEntry.activityCategory {
                    interventionVM.recordCategory(cat)
                    gameVM.processEntry(
                        category: cat,
                        minutes: lastEntry.intervalMinutes,
                        allEntries: entries,
                        context: context
                    )
                }

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

        let view = StatisticsView(
            statsVM: statsVM,
            identityProvider: identityProvider,
            settingsVM: settingsVM,
            gameVM: gameVM
        )
        .modelContainer(container)
        .preferredColorScheme(.dark)

        let window = createStandardWindow(
            title: "TimeAudit - Statistiken",
            size: NSSize(width: 560, height: 650),
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

        let view = SettingsView(
            settingsVM: settingsVM,
            identityProvider: identityProvider
        )
        .modelContainer(container)
        .preferredColorScheme(.dark)

        let window = createStandardWindow(
            title: "TimeAudit - Einstellungen",
            size: NSSize(width: 420, height: 550),
            content: view
        )
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Create a normal, interactive NSWindow
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
            settingsVM: settingsVM,
            identityProvider: identityProvider
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
