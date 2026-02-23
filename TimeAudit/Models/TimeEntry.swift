import Foundation
import SwiftData

// MARK: - Time Entry Model

/// A single time tracking entry representing what the user did during an interval.
@Model
final class TimeEntry {
    /// When this entry was logged
    var timestamp: Date

    /// The category name (matches ActivityCategory.rawValue)
    var category: String

    /// Optional free-text note
    var note: String?

    /// Optional project tag for grouping
    var project: String?

    /// Duration of the interval in minutes (15, 30, or 60)
    var intervalMinutes: Int

    init(
        timestamp: Date = .now,
        category: String,
        note: String? = nil,
        project: String? = nil,
        intervalMinutes: Int = 15
    ) {
        self.timestamp = timestamp
        self.category = category
        self.note = note
        self.project = project
        self.intervalMinutes = intervalMinutes
    }

    /// Convenience: get the ActivityCategory enum value
    var activityCategory: ActivityCategory? {
        ActivityCategory(rawValue: category)
    }
}
