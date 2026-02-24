import EventKit
import Foundation

// MARK: - Calendar Exporter
// Creates EventKit events for each log entry in three color-coded calendars.

final class CalendarExporter {

    static let shared = CalendarExporter()
    private init() {}

    private let store = EKEventStore()

    // Calendar names per category
    private let calendarName: [ActivityCategory: String] = [
        .productive: "TimeAudit – Umsatzgenerierend",
        .neutral:    "TimeAudit – Neutral",
        .harmful:    "TimeAudit – Schädlich",
    ]

    // Calendar colors (green / gray / red)
    private let calendarColor: [ActivityCategory: CGColor] = [
        .productive: CGColor(red: 0.13, green: 0.69, blue: 0.30, alpha: 1),
        .neutral:    CGColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1),
        .harmful:    CGColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1),
    ]

    // MARK: - Authorization

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess ||
        EKEventStore.authorizationStatus(for: .event) == .writeOnly
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestWriteOnlyAccessToEvents { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Create Event

    func createEvent(for entry: TimeEntry) {
        guard isAuthorized else { return }
        guard let cat = ActivityCategory(rawValue: entry.categoryValue) else { return }
        guard let calendar = getOrCreateCalendar(for: cat) else { return }

        let event       = EKEvent(eventStore: store)
        event.title     = entry.note
        event.startDate = entry.timestamp
        event.endDate   = Calendar.current.date(
            byAdding: .minute, value: entry.intervalMinutes, to: entry.timestamp
        ) ?? entry.timestamp
        event.calendar  = calendar
        event.notes     = cat.displayName

        try? store.save(event, span: .thisEvent, commit: true)
    }

    // MARK: - Calendar Management

    private func getOrCreateCalendar(for cat: ActivityCategory) -> EKCalendar? {
        guard let name = calendarName[cat] else { return nil }

        // Return existing calendar if it already exists
        if let existing = store.calendars(for: .event).first(where: { $0.title == name }) {
            return existing
        }

        // Create a new calendar with the category color
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title   = name
        cal.source  = bestSource()
        if let color = calendarColor[cat] { cal.cgColor = color }

        try? store.saveCalendar(cal, commit: true)
        return cal
    }

    /// Pick the best calendar source: prefer iCloud, fall back to local.
    private func bestSource() -> EKSource? {
        store.sources.first(where: { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") })
            ?? store.sources.first(where: { $0.sourceType == .calDAV })
            ?? store.defaultCalendarForNewEvents?.source
    }
}
