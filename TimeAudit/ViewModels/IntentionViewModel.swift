import Foundation
import SwiftData
import Observation

// MARK: - Intention ViewModel

/// Manages daily morning intention and evening debrief state.
@Observable
final class IntentionViewModel {

    var todayIntention: DailyIntention?

    /// Set to true when the morning popup should be shown
    var shouldShowMorningPopup: Bool = false

    /// Set to true when the evening debrief popup should be shown
    var shouldShowEveningDebrief: Bool = false

    // MARK: - Morning Check

    /// Called on app launch. Shows morning popup if after 8:00 and no intention yet today.
    func checkMorning(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Load today's intention
        let today = calendar.startOfDay(for: now)
        loadTodayIntention(today: today, context: context)

        guard hour >= 8, todayIntention == nil else { return }

        // Only prompt once per day (avoid repeated prompts on re-launch)
        let lastPromptKey = "lastMorningPromptDate"
        let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date
        let alreadyPromptedToday = lastPrompt.map { calendar.isDateInToday($0) } ?? false

        if !alreadyPromptedToday {
            shouldShowMorningPopup = true
            UserDefaults.standard.set(now, forKey: lastPromptKey)
        }
    }

    /// Called from the evening timer (17:30). Shows debrief if intention exists but not completed.
    func checkEvening(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        loadTodayIntention(today: today, context: context)

        if let intention = todayIntention, !intention.debriefCompleted {
            shouldShowEveningDebrief = true
        }
    }

    private func loadTodayIntention(today: Date, context: ModelContext) {
        let descriptor = FetchDescriptor<DailyIntention>(
            predicate: #Predicate { $0.date >= today }
        )
        if let intentions = try? context.fetch(descriptor) {
            todayIntention = intentions.first
        }
    }

    // MARK: - Create Intention

    func createIntention(
        priority1: String,
        priority2: String,
        priority3: String,
        avoidance: String,
        context: ModelContext
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let intention = DailyIntention(
            date: today,
            priority1: priority1,
            priority2: priority2,
            priority3: priority3,
            avoidance: avoidance
        )
        context.insert(intention)
        try? context.save()
        todayIntention = intention
        shouldShowMorningPopup = false
    }

    // MARK: - Complete Debrief

    func completeDebrief(
        priority1Done: Bool,
        priority2Done: Bool,
        priority3Done: Bool,
        biggestWin: String,
        whatToRepeat: String,
        context: ModelContext
    ) {
        guard let intention = todayIntention else { return }
        intention.priority1Done = priority1Done
        intention.priority2Done = priority2Done
        intention.priority3Done = priority3Done
        intention.biggestWin = biggestWin
        intention.whatToRepeat = whatToRepeat
        intention.debriefCompleted = true
        try? context.save()
        shouldShowEveningDebrief = false
    }

    func dismissMorning() {
        shouldShowMorningPopup = false
    }

    func dismissEvening() {
        shouldShowEveningDebrief = false
    }
}
