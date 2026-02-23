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
                    Text("Gesamt: \(StatisticsViewModel.formatMinutes(statsVM.todayTotalMinutes))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                FocusScoreView(score: statsVM.todayFocusScore, size: 70)
            }

            // Bar chart
            if !statsVM.todayCategoryMinutes.isEmpty {
                Chart(statsVM.todayCategoryMinutes, id: \.category) { item in
                    BarMark(
                        x: .value("Minuten", item.minutes),
                        y: .value("Kategorie", item.category.rawValue)
                    )
                    .foregroundStyle(item.category.color)
                    .annotation(position: .trailing) {
                        Text("\(StatisticsViewModel.formatMinutes(item.minutes)) (\(Int(statsVM.percentage(for: item.minutes)))%)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(statsVM.todayCategoryMinutes.count * 36))
            } else {
                ContentUnavailableView(
                    "Noch keine Daten",
                    systemImage: "clock",
                    description: Text("Logge deine erste Aktivitaet, um die Tagesuebersicht zu sehen.")
                )
            }

            // Best/Worst hour
            if statsVM.bestHour != nil || statsVM.worstHour != nil {
                Divider()
                HStack(spacing: 24) {
                    if let best = statsVM.bestHour {
                        Label {
                            Text("Produktivste Stunde: \(StatisticsViewModel.formatHour(best))")
                                .font(.system(size: 12))
                        } icon: {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    if let worst = statsVM.worstHour {
                        Label {
                            Text("Am wenigsten produktiv: \(StatisticsViewModel.formatHour(worst))")
                                .font(.system(size: 12))
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
