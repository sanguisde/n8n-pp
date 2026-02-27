import SwiftUI
import Charts

// MARK: - Weekly Chart View

/// Stacked bar chart showing category breakdown for each day of the past week.
struct WeeklyChartView: View {
    let statsVM: StatisticsViewModel

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
                    AxisMarks(values: .stride(by: .day)) { _ in
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
                    domain: ActivityCategory.allCases.map(\.displayName),
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
                StreakBadge(days: statsVM.noHarmfulStreak, label: "Fokussiert")
            }
        }
        .padding(16)
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(ActivityCategory.allCases) { cat in
                HStack(spacing: 4) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                    Text(cat.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
