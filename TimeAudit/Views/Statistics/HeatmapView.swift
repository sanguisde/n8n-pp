import SwiftUI
import Charts

// MARK: - Heatmap View

/// GitHub-style contribution heatmap showing activity patterns by weekday and hour.
struct HeatmapView: View {
    let statsVM: StatisticsViewModel

    private let weekdays = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktivitaets-Heatmap")
                .font(.system(size: 18, weight: .bold))

            Text("Letzte 4 Wochen - Haeufigste Kategorie pro Zeitslot")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if !statsVM.heatmapData.isEmpty && statsVM.heatmapData.contains(where: { $0.minutes > 0 }) {
                Chart(statsVM.heatmapData.filter { $0.minutes > 0 }, id: \.hour) { item in
                    RectangleMark(
                        x: .value("Stunde", item.hour),
                        y: .value("Tag", weekdays[item.weekday]),
                        width: .ratio(0.9),
                        height: .ratio(0.9)
                    )
                    .foregroundStyle(item.category?.color.opacity(opacityForMinutes(item.minutes)) ?? Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: [0, 4, 8, 12, 16, 20]) { value in
                        AxisValueLabel {
                            if let h = value.as(Int.self) {
                                Text("\(h)h")
                                    .font(.system(size: 9))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 180)

                // Color legend
                heatmapLegend
            } else {
                ContentUnavailableView(
                    "Noch keine Heatmap-Daten",
                    systemImage: "square.grid.3x3",
                    description: Text("Die Heatmap baut sich mit der Zeit automatisch auf.")
                )
            }
        }
        .padding(16)
    }

    private func opacityForMinutes(_ minutes: Int) -> Double {
        let maxExpected = 60.0
        return min(1.0, max(0.2, Double(minutes) / maxExpected))
    }

    private var heatmapLegend: some View {
        HStack(spacing: 16) {
            ForEach(ActivityCategory.allCases) { cat in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cat.color)
                        .frame(width: 12, height: 12)
                    Text(cat.displayName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
