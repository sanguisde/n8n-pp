import SwiftUI
import SwiftData

// MARK: - Statistics View

/// Tab-based statistics window: Today / Week / Heatmap.
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.timestamp, order: .reverse) private var allEntries: [TimeEntry]

    @Bindable var statsVM: StatisticsViewModel

    @State private var selectedTab = 0
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Heute").tag(0)
                Text("Woche").tag(1)
                Text("Heatmap").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Tab content
            ScrollView {
                switch selectedTab {
                case 0:
                    DailyOverviewView(statsVM: statsVM)
                case 1:
                    WeeklyChartView(statsVM: statsVM)
                case 2:
                    HeatmapView(statsVM: statsVM)
                default:
                    EmptyView()
                }
            }

            Divider()

            // Export button
            HStack {
                if let msg = exportMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }

                Spacer()

                Button(action: exportCSV) {
                    Label("CSV Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 500, height: 480)
        .preferredColorScheme(.dark)
        .onAppear {
            statsVM.refresh(entries: allEntries)
        }
    }

    private func exportCSV() {
        if let url = CSVExporter.exportToFile(entries: allEntries) {
            exportMessage = "Exportiert: \(url.lastPathComponent)"
            // Open in Finder
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)

            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportMessage = nil
            }
        } else {
            exportMessage = "Export fehlgeschlagen"
        }
    }
}
