import SwiftUI
import SwiftData

// MARK: - Logging ViewModel

/// Manages the category selection and entry saving for the logging popup.
@Observable
final class LoggingViewModel {
    /// Currently selected category
    var selectedCategory: ActivityCategory?

    /// Optional note text
    var noteText: String = ""

    /// Optional project tag
    var projectText: String = ""

    /// Smart default suggestion based on recent entries
    var suggestedCategory: ActivityCategory?

    /// Whether an idle state was detected (suggests Pause/Schlaf)
    var idleDetected: Bool = false

    /// Last 3 logged categories for smart default calculation
    private var recentCategories: [ActivityCategory] = []

    /// Save the current entry to SwiftData
    func saveEntry(context: ModelContext, intervalMinutes: Int) -> Bool {
        guard let category = selectedCategory else { return false }

        let entry = TimeEntry(
            timestamp: .now,
            category: category.rawValue,
            note: noteText.isEmpty ? nil : noteText,
            project: projectText.isEmpty ? nil : projectText,
            intervalMinutes: intervalMinutes
        )

        context.insert(entry)

        // Save last category for menu bar icon indicator
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategory")

        // Update recent categories for smart defaults
        recentCategories.append(category)
        if recentCategories.count > 3 {
            recentCategories.removeFirst()
        }

        // Reset for next entry
        reset()

        return true
    }

    /// Reset the form state
    func reset() {
        selectedCategory = nil
        noteText = ""
        projectText = ""
        idleDetected = false
        updateSuggestion()
    }

    /// Update smart default suggestion
    func updateSuggestion() {
        if idleDetected {
            suggestedCategory = .pause
            return
        }

        // If last 3 categories are the same, suggest that category
        if recentCategories.count >= 3 {
            let last3 = Array(recentCategories.suffix(3))
            if Set(last3).count == 1 {
                suggestedCategory = last3.first
                return
            }
        }

        suggestedCategory = nil
    }

    /// Set idle state and update suggestion
    func setIdleDetected(_ idle: Bool) {
        idleDetected = idle
        updateSuggestion()
    }

    /// Handle keyboard shortcut selection
    func selectByShortcut(_ key: String) {
        if let category = ActivityCategory.allCases.first(where: { $0.shortcutKey == key }) {
            selectedCategory = category
        }
    }

    /// Load recent categories from existing entries
    func loadRecentCategories(from entries: [TimeEntry]) {
        recentCategories = entries
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(3)
            .reversed()
            .compactMap { ActivityCategory(rawValue: $0.category) }
        updateSuggestion()
    }
}
