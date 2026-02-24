import SwiftUI
import SwiftData

// MARK: - Statistics ViewModel

/// Aggregates time entries for daily/weekly views, focus score, streaks, and analysis.
@Observable
final class StatisticsViewModel {

    // MARK: - Daily Stats

    /// Total minutes per category for today
    var todayCategoryMinutes: [(category: ActivityCategory, minutes: Int)] = []

    /// Today's focus score (0-100)
    var todayFocusScore: Int = 50

    /// Average focus score over last 7 days
    var weeklyAverageFocusScore: Int = 50

    // MARK: - Streaks

    /// Consecutive days with >= 4h productive work
    var productiveStreak: Int = 0

    /// Consecutive days with 0 harmful time
    var noHarmfulStreak: Int = 0

    // MARK: - Best/Worst Hour

    /// Most productive hour of the day (0-23)
    var bestHour: Int?

    /// Least productive hour of the day (0-23)
    var worstHour: Int?

    // MARK: - Weekly Data

    /// Weekly aggregated data: (date, category, minutes)
    var weeklyData: [(date: Date, category: ActivityCategory, minutes: Int)] = []

    // MARK: - Heatmap Data

    /// Heatmap: (weekday 0-6, hour 0-23, dominant category, total minutes)
    var heatmapData: [(weekday: Int, hour: Int, category: ActivityCategory?, minutes: Int)] = []

    // MARK: - Computation

    /// Refresh all statistics from the given entries
    func refresh(entries: [TimeEntry]) {
        computeToday(entries: entries)
        computeWeekly(entries: entries)
        computeStreaks(entries: entries)
        computeBestWorstHour(entries: entries)
        computeHeatmap(entries: entries)
    }

    /// Compute today's category breakdown and focus score
    private func computeToday(entries: [TimeEntry]) {
        let calendar = Calendar.current
        let todayEntries = entries.filter { calendar.isDateInToday($0.timestamp) }

        var minutesByCategory: [ActivityCategory: Int] = [:]
        for entry in todayEntries {
            if let cat = ActivityCategory(rawValue: entry.categoryValue) {
                minutesByCategory[cat, default: 0] += entry.intervalMinutes
            }
        }

        todayCategoryMinutes = minutesByCategory
            .map { (category: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }

        todayFocusScore = calculateFocusScore(minutesByCategory: minutesByCategory)
    }

    /// Compute weekly breakdown for charts
    private func computeWeekly(entries: [TimeEntry]) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!

        let weekEntries = entries.filter { $0.timestamp >= weekAgo }

        var grouped: [Date: [ActivityCategory: Int]] = [:]
        for entry in weekEntries {
            let day = calendar.startOfDay(for: entry.timestamp)
            if let cat = ActivityCategory(rawValue: entry.categoryValue) {
                grouped[day, default: [:]][cat, default: 0] += entry.intervalMinutes
            }
        }

        weeklyData = grouped.flatMap { (date, cats) in
            cats.map { (date: date, category: $0.key, minutes: $0.value) }
        }.sorted { $0.date < $1.date }

        // Weekly average focus score
        let dailyScores: [Int] = grouped.map { calculateFocusScore(minutesByCategory: $0.value) }
        weeklyAverageFocusScore = dailyScores.isEmpty ? 50 : dailyScores.reduce(0, +) / dailyScores.count
    }

    /// Compute productive and no-harmful streaks
    private func computeStreaks(entries: [TimeEntry]) {
        let calendar = Calendar.current

        // Group entries by day
        var dayData: [Date: [ActivityCategory: Int]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            if let cat = ActivityCategory(rawValue: entry.categoryValue) {
                dayData[day, default: [:]][cat, default: 0] += entry.intervalMinutes
            }
        }

        let sortedDays = dayData.keys.sorted().reversed()

        // Productive streak: consecutive days with >= 240 min (4h) productive
        productiveStreak = 0
        for day in sortedDays {
            let cats = dayData[day] ?? [:]
            let productiveMinutes = cats[.productive] ?? 0
            if productiveMinutes >= 240 {
                productiveStreak += 1
            } else {
                break
            }
        }

        // No harmful streak: consecutive days with 0 min harmful
        noHarmfulStreak = 0
        for day in sortedDays {
            let cats = dayData[day] ?? [:]
            let harmfulMinutes = cats[.harmful] ?? 0
            if harmfulMinutes == 0 {
                noHarmfulStreak += 1
            } else {
                break
            }
        }
    }

    /// Compute best and worst productivity hours over the last 7 days
    private func computeBestWorstHour(entries: [TimeEntry]) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        let weekEntries = entries.filter { $0.timestamp >= weekAgo }

        var hourScores: [Int: (weightedSum: Double, totalMinutes: Int)] = [:]
        for entry in weekEntries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            let weight = ActivityCategory(rawValue: entry.categoryValue)?.productivityWeight ?? 0
            var data = hourScores[hour, default: (0, 0)]
            data.weightedSum += weight * Double(entry.intervalMinutes)
            data.totalMinutes += entry.intervalMinutes
            hourScores[hour] = data
        }

        let avgScores = hourScores.compactMap { (hour, data) -> (Int, Double)? in
            guard data.totalMinutes > 0 else { return nil }
            return (hour, data.weightedSum / Double(data.totalMinutes))
        }

        bestHour = avgScores.max(by: { $0.1 < $1.1 })?.0
        worstHour = avgScores.min(by: { $0.1 < $1.1 })?.0
    }

    /// Compute heatmap data (weekday x hour grid)
    private func computeHeatmap(entries: [TimeEntry]) {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .day, value: -28, to: .now)!
        let recentEntries = entries.filter { $0.timestamp >= monthAgo }

        var grid: [Int: [Int: [ActivityCategory: Int]]] = [:]
        for entry in recentEntries {
            let weekday = calendar.component(.weekday, from: entry.timestamp) - 1
            let hour = calendar.component(.hour, from: entry.timestamp)
            if let cat = ActivityCategory(rawValue: entry.categoryValue) {
                grid[weekday, default: [:]][hour, default: [:]][cat, default: 0] += entry.intervalMinutes
            }
        }

        heatmapData = []
        for weekday in 0..<7 {
            for hour in 0..<24 {
                let cats = grid[weekday]?[hour] ?? [:]
                let dominant = cats.max(by: { $0.value < $1.value })?.key
                let total = cats.values.reduce(0, +)
                heatmapData.append((weekday: weekday, hour: hour, category: dominant, minutes: total))
            }
        }
    }

    // MARK: - Focus Score Calculation

    /// Calculate focus score from minutes by category.
    /// Score = (weighted sum / total) * 50 + 50, clamped to 0...100
    func calculateFocusScore(minutesByCategory: [ActivityCategory: Int]) -> Int {
        let totalMinutes = minutesByCategory.values.reduce(0, +)
        guard totalMinutes > 0 else { return 50 }

        let weightedSum = minutesByCategory.reduce(0.0) { sum, pair in
            sum + pair.key.productivityWeight * Double(pair.value)
        }

        let normalized = (weightedSum / Double(totalMinutes)) * 50.0 + 50.0
        return Int(max(0, min(100, normalized)))
    }

    // MARK: - Formatting Helpers

    /// Format minutes as "H:MM"
    static func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h):\(String(format: "%02d", m))"
        }
        return "0:\(String(format: "%02d", m))"
    }

    /// Format hour as "HH:00"
    static func formatHour(_ hour: Int) -> String {
        "\(String(format: "%02d", hour)):00"
    }

    /// Total logged minutes today
    var todayTotalMinutes: Int {
        todayCategoryMinutes.reduce(0) { $0 + $1.minutes }
    }

    /// Percentage of today's time for a category
    func percentage(for minutes: Int) -> Double {
        guard todayTotalMinutes > 0 else { return 0 }
        return Double(minutes) / Double(todayTotalMinutes) * 100
    }
}
