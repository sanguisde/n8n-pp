import SwiftUI
import Charts

// MARK: - Daily Overview View

/// Shows today's time breakdown with horizontal bars and a focus score.
struct DailyOverviewView: View {
    let statsVM: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Focus score header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heute")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("Gesamt: \(StatisticsViewModel.formatMinutes(statsVM.todayTotalMinutes))")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                Spacer()
                FocusScoreView(score: statsVM.todayFocusScore, size: 70)
            }

            // Bar chart
            if !statsVM.todayCategoryMinutes.isEmpty {
                Chart(statsVM.todayCategoryMinutes, id: \.category) { item in
                    BarMark(
                        x: .value("Minuten", item.minutes),
                        y: .value("Kategorie", item.category.displayName)
                    )
                    .foregroundStyle(item.category.color)
                    .annotation(position: .trailing) {
                        Text("\(StatisticsViewModel.formatMinutes(item.minutes)) (\(Int(statsVM.percentage(for: item.minutes)))%)")
                            .font(.system(size: 10))
                            .foregroundStyle(ThemeColors.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartPlotStyle { plotArea in
                    plotArea.background(ThemeColors.cardBackground.opacity(0.3))
                }
                .frame(height: CGFloat(statsVM.todayCategoryMinutes.count * 44))
            } else {
                ContentUnavailableView(
                    "Noch keine Daten",
                    systemImage: "clock",
                    description: Text("Logge deine erste Aktivitaet, um die Tagesuebersicht zu sehen.")
                )
            }

            // Best/Worst hour
            if statsVM.bestHour != nil || statsVM.worstHour != nil {
                Rectangle()
                    .fill(ThemeColors.subtleBorder)
                    .frame(height: 0.5)
                HStack(spacing: 24) {
                    if let best = statsVM.bestHour {
                        Label {
                            Text("Produktivste Stunde: \(StatisticsViewModel.formatHour(best))")
                                .font(.system(size: 12))
                                .foregroundStyle(ThemeColors.textPrimary)
                        } icon: {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    if let worst = statsVM.worstHour {
                        Label {
                            Text("Am wenigsten produktiv: \(StatisticsViewModel.formatHour(worst))")
                                .font(.system(size: 12))
                                .foregroundStyle(ThemeColors.textPrimary)
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}
