import Foundation
import SwiftData

// MARK: - Daily Intention

/// Stores the morning intention (3 priorities + avoidance) and evening debrief results.
@Model
final class DailyIntention {

    /// The calendar day this intention belongs to (start of day)
    var date: Date

    // Morning: What to focus on
    var priority1: String
    var priority2: String
    var priority3: String

    /// What to actively avoid today (distraction commitment)
    var avoidance: String

    // Evening debrief: Did you complete your priorities?
    var priority1Done: Bool
    var priority2Done: Bool
    var priority3Done: Bool

    /// Biggest win of the day (free text)
    var biggestWin: String

    /// What to repeat tomorrow
    var whatToRepeat: String

    /// Whether the evening debrief has been completed
    var debriefCompleted: Bool

    init(
        date: Date = Calendar.current.startOfDay(for: Date()),
        priority1: String = "",
        priority2: String = "",
        priority3: String = "",
        avoidance: String = ""
    ) {
        self.date = date
        self.priority1 = priority1
        self.priority2 = priority2
        self.priority3 = priority3
        self.avoidance = avoidance
        self.priority1Done = false
        self.priority2Done = false
        self.priority3Done = false
        self.biggestWin = ""
        self.whatToRepeat = ""
        self.debriefCompleted = false
    }
}
