import Foundation

// MARK: - CSV Exporter

/// Exports TimeEntry data to CSV format.
struct CSVExporter {

    /// Generate CSV string from time entries
    static func generateCSV(from entries: [TimeEntry]) -> String {
        var csv = "Timestamp,Category,Note,Interval (min)\n"

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let ts = formatter.string(from: entry.timestamp)
            let cat = escapeCSV(entry.activityCategory?.displayName ?? "Unbekannt")
            let note = escapeCSV(entry.note)
            let interval = "\(entry.intervalMinutes)"
            csv += "\(ts),\(cat),\(note),\(interval)\n"
        }

        return csv
    }

    /// Save CSV to a file and return the URL
    static func exportToFile(entries: [TimeEntry], filename: String = "TimeAudit_Export") -> URL? {
        let csv = generateCSV(from: entries)

        let dateStr = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd_HHmmss"
            return f.string(from: .now)
        }()

        let fullName = "\(filename)_\(dateStr).csv"

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentsURL.appendingPathComponent(fullName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV export failed: \(error)")
            return nil
        }
    }

    /// Escape a field for CSV (handle commas, quotes, newlines)
    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
