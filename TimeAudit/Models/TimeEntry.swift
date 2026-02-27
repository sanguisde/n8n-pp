import Foundation
import SwiftData

// MARK: - Time Entry Model

/// A single time tracking entry representing what the user did during an interval.
@Model
final class TimeEntry {
    /// When this entry was logged
    var timestamp: Date

    /// The category value (1 = productive, 2 = neutral, 3 = harmful)
    var categoryValue: Int

    /// Mandatory free-text note describing what was done
    var note: String

    /// Duration of the interval in minutes (15, 30, or 60)
    var intervalMinutes: Int

    init(
        timestamp: Date = .now,
        categoryValue: Int,
        note: String,
        intervalMinutes: Int = 15
    ) {
        self.timestamp = timestamp
        self.categoryValue = categoryValue
        self.note = note
        self.intervalMinutes = intervalMinutes
    }

    /// Convenience: get the ActivityCategory enum value
    var activityCategory: ActivityCategory? {
        ActivityCategory(rawValue: categoryValue)
    }
}
