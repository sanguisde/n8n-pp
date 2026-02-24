import SwiftUI
import SwiftData

// MARK: - Intervention ViewModel

/// Manages the Loop-Breaker intervention logic.
/// Triggers when 2 consecutive Category 3 (harmful) logs are detected.
@Observable
final class InterventionViewModel {

    /// Number of consecutive harmful category logs
    var consecutiveHarmfulCount: Int = 0

    /// Whether the intervention popup should be shown
    var shouldShowIntervention: Bool = false

    /// Whether the 1-minute timer is running
    var isTimerRunning: Bool = false

    /// Seconds remaining on the intervention timer
    var timerSecondsRemaining: Int = 60

    /// Whether the intervention was completed (timer finished)
    var interventionCompleted: Bool = false

    @ObservationIgnored
    private var timer: Timer?

    /// Record a new log entry and check if intervention should trigger
    func recordCategory(_ category: ActivityCategory) {
        if category == .harmful {
            consecutiveHarmfulCount += 1
        } else {
            consecutiveHarmfulCount = 0
        }

        // Trigger intervention after 2 consecutive harmful logs
        if consecutiveHarmfulCount >= 2 {
            shouldShowIntervention = true
        }
    }

    /// Load consecutive count from recent entries
    func loadFromEntries(_ entries: [TimeEntry]) {
        let sorted = entries.sorted { $0.timestamp > $1.timestamp }
        consecutiveHarmfulCount = 0
        for entry in sorted {
            if entry.activityCategory == .harmful {
                consecutiveHarmfulCount += 1
            } else {
                break
            }
        }
    }

    /// Start the 1-minute breathing/prayer timer
    func startTimer() {
        isTimerRunning = true
        timerSecondsRemaining = 60
        interventionCompleted = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.timerSecondsRemaining > 0 {
                    self.timerSecondsRemaining -= 1
                } else {
                    self.completeIntervention()
                }
            }
        }
    }

    /// Complete the intervention
    func completeIntervention() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        interventionCompleted = true

        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.dismiss()
        }
    }

    /// Dismiss the intervention (skip or after completion)
    func dismiss() {
        timer?.invalidate()
        timer = nil
        shouldShowIntervention = false
        isTimerRunning = false
        interventionCompleted = false
        timerSecondsRemaining = 60
        // Don't reset consecutiveHarmfulCount - it resets when a non-harmful category is logged
    }

    deinit {
        timer?.invalidate()
    }
}
