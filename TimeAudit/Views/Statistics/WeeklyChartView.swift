import SwiftUI
import Charts

// MARK: - Weekly Chart View

/// Stacked bar chart showing category breakdown for each day of the past week.
struct WeeklyChartView: View {
    let statsVM: StatisticsViewModel

    private var weekDayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "E"
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Wochenuebersicht")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Ø Score")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(statsVM.weeklyAverageFocusScore)")
                        .font(.system(size: 16, weight: .bold))
                }
            }

            if !statsVM.weeklyData.isEmpty {
                Chart(statsVM.weeklyData, id: \.date) { item in
                    BarMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("Minuten", item.minutes)
                    )
                    .foregroundStyle(item.category.color)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(StatisticsViewModel.formatMinutes(v))
                                    .font(.system(size: 9))
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(
                    domain: ActivityCategory.allCases.map(\.rawValue),
                    range: ActivityCategory.allCases.map(\.color)
                )
                .frame(height: 200)

                // Legend
                legendView
            } else {
                ContentUnavailableView(
                    "Noch keine Wochendaten",
                    systemImage: "chart.bar",
                    description: Text("Nach einigen Tagen Nutzung erscheint hier die Wochenuebersicht.")
                )
            }

            // Streaks
            HStack(spacing: 16) {
                StreakBadge(days: statsVM.productiveStreak, label: "Produktiv")
                StreakBadge(days: statsVM.noDistractionStreak, label: "Fokussiert")
            }
        }
        .padding(16)
    }

    private var legendView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 120))
        ], spacing: 4) {
            ForEach(ActivityCategory.allCases) { cat in
                HStack(spacing: 4) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 6, height: 6)
                    Text(cat.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
