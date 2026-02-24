import SwiftUI
import SwiftData

// MARK: - Statistics View

/// Tab-based statistics window: Today / Week / Heatmap.
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.timestamp, order: .reverse) private var allEntries: [TimeEntry]

    @Bindable var statsVM: StatisticsViewModel
    let identityProvider: IdentityProvider
    let settingsVM: SettingsViewModel

    @State private var selectedTab = 0
    @State private var exportMessage: String?

    private var goalMinutes: Int {
        settingsVM.useAdaptiveGoal ? statsVM.adaptiveGoalMinutes : settingsVM.dailyGoalMinutes
    }

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
                    DailyOverviewView(
                        statsVM: statsVM,
                        identityProvider: identityProvider,
                        goalMinutes: goalMinutes
                    )
                case 1:
                    WeeklyChartView(statsVM: statsVM)
                case 2:
                    HeatmapView(statsVM: statsVM)
                default:
                    EmptyView()
                }
            }

            Rectangle()
                .fill(ThemeColors.subtleBorder)
                .frame(height: 0.5)

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
                        .foregroundStyle(ThemeColors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ThemeColors.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ThemeColors.accent.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 560, height: 600)
        .background(ThemeColors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            statsVM.refresh(entries: allEntries)
        }
    }

    private func exportCSV() {
        if let url = CSVExporter.exportToFile(entries: allEntries) {
            exportMessage = "Exportiert: \(url.lastPathComponent)"
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                exportMessage = nil
            }
        } else {
            exportMessage = "Export fehlgeschlagen"
        }
    }
}
