import SwiftUI
import SwiftData

// MARK: - Logging ViewModel

/// Manages the category selection and entry saving for the logging popup.
@Observable
final class LoggingViewModel {
    /// Currently selected category
    var selectedCategory: ActivityCategory?

    /// Mandatory note text
    var noteText: String = ""

    /// Smart default suggestion based on recent entries
    var suggestedCategory: ActivityCategory?

    /// Last 3 logged categories for smart default calculation
    private var recentCategories: [ActivityCategory] = []

    /// Save the current entry to SwiftData. Note is mandatory.
    func saveEntry(context: ModelContext, intervalMinutes: Int) -> Bool {
        guard let category = selectedCategory else { return false }
        let trimmedNote = noteText.trimmingCharacters(in: .whitespaces)
        guard !trimmedNote.isEmpty else { return false }

        let entry = TimeEntry(
            timestamp: .now,
            categoryValue: category.rawValue,
            note: trimmedNote,
            intervalMinutes: intervalMinutes
        )

        context.insert(entry)

        // Save last category and note for menu bar icon indicator and repeat-last-entry
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategoryValue")
        UserDefaults.standard.set(trimmedNote, forKey: "lastNoteText")

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
        updateSuggestion()
    }

    /// Update smart default suggestion
    func updateSuggestion() {
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

    /// Handle keyboard shortcut selection
    func selectByShortcut(_ key: String) {
        if let category = ActivityCategory.allCases.first(where: { $0.shortcutKey == key }) {
            selectedCategory = category
        }
    }

    /// Last saved entry (category + note) for the repeat-last-entry feature
    var lastEntry: (category: ActivityCategory, note: String)? {
        guard let note = UserDefaults.standard.string(forKey: "lastNoteText"), !note.isEmpty,
              let rawVal = UserDefaults.standard.object(forKey: "lastCategoryValue") as? Int,
              let cat = ActivityCategory(rawValue: rawVal) else { return nil }
        return (cat, note)
    }

    /// Pre-fill note + category from the last saved entry
    func repeatLastEntry() {
        guard let last = lastEntry else { return }
        noteText = last.note
        selectedCategory = last.category
    }

    /// Load recent categories from existing entries
    func loadRecentCategories(from entries: [TimeEntry]) {
        recentCategories = entries
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(3)
            .reversed()
            .compactMap { ActivityCategory(rawValue: $0.categoryValue) }
        updateSuggestion()
    }
}
