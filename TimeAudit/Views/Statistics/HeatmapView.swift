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
                // Swift Charts heatmap using RectangleMark
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
                    AxisMarks { value in
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

    /// Map minutes to opacity (more minutes = more opaque)
    private func opacityForMinutes(_ minutes: Int) -> Double {
        let maxExpected = 60.0
        return min(1.0, max(0.2, Double(minutes) / maxExpected))
    }

    private var heatmapLegend: some View {
        HStack(spacing: 16) {
            Text("Wenig")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            HStack(spacing: 2) {
                ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(opacity))
                        .frame(width: 12, height: 12)
                }
            }

            Text("Viel")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}
