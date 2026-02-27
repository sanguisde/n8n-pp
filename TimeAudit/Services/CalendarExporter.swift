import EventKit
import Foundation

// MARK: - Calendar Exporter
// Creates EventKit events for each log entry in three color-coded calendars.

final class CalendarExporter {

    static let shared = CalendarExporter()
    private init() {}

    private let store = EKEventStore()

    // MARK: - Authorization

    /// True for any "granted" state, future-proof against new enum cases in macOS 26+.
    var isAuthorized: Bool {
        let s = EKEventStore.authorizationStatus(for: .event)
        return s != .notDetermined && s != .restricted && s != .denied
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestWriteOnlyAccessToEvents { [weak self] granted, error in
            if let error { print("[Cal] requestAccess error: \(error)") }
            // Refresh store sources after permission is granted
            if granted { self?.store.refreshSourcesIfNecessary() }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Create Event

    func createEvent(for entry: TimeEntry) {
        guard isAuthorized else {
            print("[Cal] skipped – not authorized (status: \(EKEventStore.authorizationStatus(for: .event).rawValue))")
            return
        }
        guard let cat = ActivityCategory(rawValue: entry.categoryValue) else { return }

        let calendar: EKCalendar
        do {
            calendar = try getOrCreateCalendar(for: cat)
        } catch {
            print("[Cal] getOrCreateCalendar failed: \(error)")
            return
        }

        let event       = EKEvent(eventStore: store)
        event.title     = entry.note.isEmpty ? cat.displayName : entry.note
        event.startDate = entry.timestamp
        event.endDate   = Calendar.current.date(
            byAdding: .minute, value: max(1, entry.intervalMinutes), to: entry.timestamp
        ) ?? entry.timestamp
        event.calendar  = calendar
        event.notes     = "TimeAudit · \(cat.displayName)"

        do {
            try store.save(event, span: .thisEvent, commit: true)
            print("[Cal] event saved: \"\(event.title ?? "")\" in \(calendar.title)")
        } catch {
            print("[Cal] save event failed: \(error)")
        }
    }

    // MARK: - Calendar Management

    private func getOrCreateCalendar(for cat: ActivityCategory) throws -> EKCalendar {
        let name = calendarTitle(for: cat)

        // Reuse existing if already created
        if let existing = store.calendars(for: .event).first(where: { $0.title == name }) {
            return existing
        }

        // Pick source: defaultCalendarForNewEvents is always the most reliable choice
        guard let source = store.defaultCalendarForNewEvents?.source
                        ?? store.sources.first(where: { $0.sourceType == .local })
                        ?? store.sources.first else {
            // Last resort: just use the default calendar directly
            if let def = store.defaultCalendarForNewEvents {
                print("[Cal] no source found – using default calendar '\(def.title)'")
                return def
            }
            throw CalError.noSource
        }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title   = name
        cal.source  = source
        cal.cgColor = calendarColor(for: cat)

        do {
            try store.saveCalendar(cal, commit: true)
            print("[Cal] created calendar '\(name)' in source '\(source.title)'")
            return cal
        } catch {
            // Creation failed – fall back to the user's default calendar
            print("[Cal] saveCalendar failed (\(error)) – using default calendar")
            if let def = store.defaultCalendarForNewEvents { return def }
            throw error
        }
    }

    // MARK: - Names & Colors

    private func calendarTitle(for cat: ActivityCategory) -> String {
        switch cat {
        case .productive: return "TimeAudit – Umsatzgenerierend"
        case .neutral:    return "TimeAudit – Neutral"
        case .harmful:    return "TimeAudit – Schädlich"
        }
    }

    private func calendarColor(for cat: ActivityCategory) -> CGColor {
        switch cat {
        case .productive: return CGColor(red: 0.13, green: 0.69, blue: 0.30, alpha: 1)
        case .neutral:    return CGColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
        case .harmful:    return CGColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1)
        }
    }

    private enum CalError: Error {
        case noSource
    }
}
