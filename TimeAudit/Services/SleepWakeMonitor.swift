import Foundation
import AppKit

// MARK: - Sleep/Wake Monitor

/// Monitors macOS sleep/wake events via NSWorkspace notifications.
final class SleepWakeMonitor: ObservableObject {
    /// Fired when the system wakes from sleep
    var onWake: (() -> Void)?

    /// Fired when the system is about to sleep
    var onSleep: (() -> Void)?

    /// Timestamp of the last sleep event
    @Published var lastSleepTime: Date?

    /// Timestamp of the last wake event
    @Published var lastWakeTime: Date?

    private var observers: [NSObjectProtocol] = []

    func start() {
        let center = NSWorkspace.shared.notificationCenter

        let wakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWakeTime = .now
            self?.onWake?()
        }

        let sleepObserver = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastSleepTime = .now
            self?.onSleep?()
        }

        // Also monitor screen wake/sleep for more granular detection
        let screenWakeObserver = center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWakeTime = .now
            self?.onWake?()
        }

        observers = [wakeObserver, sleepObserver, screenWakeObserver]
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        stop()
    }
}
