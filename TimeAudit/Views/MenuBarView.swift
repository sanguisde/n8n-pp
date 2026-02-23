import SwiftUI
import SwiftData

// MARK: - Menu Bar View

/// Main view shown in the MenuBarExtra popover. Displays today's summary with quick actions.
struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.timestamp, order: .reverse) private var allEntries: [TimeEntry]

    @Bindable var statsVM: StatisticsViewModel
    @Bindable var timerVM: TimerViewModel
    let onLogNow: () -> Void
    let onOpenStatistics: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with score
            headerSection

            Divider().background(Color.white.opacity(0.1))

            // Today's breakdown
            todaySection

            Divider().background(Color.white.opacity(0.1))

            // Insights row
            insightsSection

            Divider().background(Color.white.opacity(0.1))

            // Action buttons
            actionsSection
        }
        .frame(width: 300)
        .preferredColorScheme(.dark)
        .onAppear {
            statsVM.refresh(entries: allEntries)
        }
        .onChange(of: allEntries.count) {
            statsVM.refresh(entries: allEntries)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TimeAudit")
                    .font(.system(size: 14, weight: .bold))
                Text(timerLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            FocusScoreView(score: statsVM.todayFocusScore, size: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var timerLabel: String {
        let min = timerVM.secondsRemaining / 60
        let sec = timerVM.secondsRemaining % 60
        return "Naechstes Log in \(min):\(String(format: "%02d", sec))"
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Heute")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            if statsVM.todayCategoryMinutes.isEmpty {
                Text("Noch keine Eintraege")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(statsVM.todayCategoryMinutes.prefix(6), id: \.category) { item in
                    categoryRow(item.category, minutes: item.minutes)
                }

                if statsVM.todayCategoryMinutes.count > 6 {
                    Text("+ \(statsVM.todayCategoryMinutes.count - 6) weitere")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func categoryRow(_ category: ActivityCategory, minutes: Int) -> some View {
        HStack(spacing: 8) {
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(category.color)
                .frame(width: CGFloat(min(120, max(8, Double(minutes) / Double(max(1, statsVM.todayTotalMinutes)) * 120))), height: 12)

            Text(category.rawValue)
                .font(.system(size: 11))
                .lineLimit(1)

            Spacer()

            Text(StatisticsViewModel.formatMinutes(minutes))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("\(Int(statsVM.percentage(for: minutes)))%")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        HStack(spacing: 12) {
            // Weekly comparison
            VStack(alignment: .leading, spacing: 2) {
                Text("vs. 7-Tage-Ø")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("Score \(statsVM.weeklyAverageFocusScore)")
                    .font(.system(size: 11, weight: .medium))
            }

            Spacer()

            // Streak
            StreakBadge(days: statsVM.productiveStreak, label: "Produktiv")

            // Best/Worst hour
            if let best = statsVM.bestHour {
                VStack(spacing: 1) {
                    Text("Best")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text(StatisticsViewModel.formatHour(best))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button(action: onLogNow) {
                    Label("Jetzt loggen", systemImage: "plus.circle")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                }

                Button(action: onOpenStatistics) {
                    Label("Statistiken", systemImage: "chart.bar")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)

            HStack(spacing: 8) {
                Button(action: onOpenSettings) {
                    Label("Einstellungen", systemImage: "gear")
                        .font(.system(size: 11))
                }

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Beenden", systemImage: "power")
                        .font(.system(size: 11))
                }
                .keyboardShortcut("q")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
