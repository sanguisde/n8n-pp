import SwiftUI
import Combine

// MARK: - Timer ViewModel

/// Manages the 15-minute interval timer, wake detection, and reminder logic.
@Observable
final class TimerViewModel {
    /// Whether the logging popup should be shown
    var shouldShowPopup: Bool = false

    /// Seconds remaining until next popup
    var secondsRemaining: Int = 0

    /// Time when the popup was first shown (for re-reminder tracking)
    var popupShownAt: Date?

    /// Whether we need to re-remind (popup open > 5 min without logging)
    var needsReReminder: Bool = false

    /// Current interval in minutes
    var intervalMinutes: Int = 15 {
        didSet {
            secondsRemaining = intervalMinutes * 60
        }
    }

    /// Timestamp of the last successful log
    @ObservationIgnored
    var lastLogTimestamp: Date {
        get {
            if let stored = UserDefaults.standard.object(forKey: "lastLogTimestamp") as? Date {
                return stored
            }
            return .now
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastLogTimestamp")
        }
    }

    private var timer: Timer?
    private var activity: NSObjectProtocol?

    /// Start the interval timer
    func start() {
        // Prevent App Nap from pausing our timer
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "TimeAudit timer must keep running"
        )

        let elapsed = Date.now.timeIntervalSince(lastLogTimestamp)
        let intervalSeconds = Double(intervalMinutes * 60)

        if elapsed >= intervalSeconds {
            // Time already exceeded, show popup immediately
            triggerPopup()
        } else {
            secondsRemaining = Int(intervalSeconds - elapsed)
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Stop the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        activity = nil
    }

    /// Called when user successfully logs an entry
    func didLog() {
        lastLogTimestamp = .now
        shouldShowPopup = false
        popupShownAt = nil
        needsReReminder = false
        secondsRemaining = intervalMinutes * 60
    }

    /// Called when system wakes from sleep - trigger popup immediately
    func handleWake() {
        let elapsed = Date.now.timeIntervalSince(lastLogTimestamp)
        if elapsed >= 60 { // At least 1 minute since last log
            triggerPopup()
        }
    }

    private func tick() {
        if shouldShowPopup {
            // Check for re-reminder (popup open for > 5 minutes)
            if let shownAt = popupShownAt,
               Date.now.timeIntervalSince(shownAt) >= 300 {
                needsReReminder = true
                popupShownAt = .now // Reset for next reminder cycle
            }
            return
        }

        secondsRemaining -= 1

        if secondsRemaining <= 0 {
            triggerPopup()
        }
    }

    private func triggerPopup() {
        shouldShowPopup = true
        popupShownAt = .now
        secondsRemaining = 0
    }

    deinit {
        stop()
    }
}
