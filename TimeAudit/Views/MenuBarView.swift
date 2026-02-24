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
            headerSection

            separator

            todaySection

            separator

            insightsSection

            separator

            actionsSection
        }
        .frame(width: 300)
        .background(ThemeColors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            statsVM.refresh(entries: allEntries)
        }
        .onChange(of: allEntries.count) {
            statsVM.refresh(entries: allEntries)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(ThemeColors.subtleBorder)
            .frame(height: 0.5)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TimeAudit")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(timerLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.textSecondary)
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
                .foregroundStyle(ThemeColors.textSecondary)

            if statsVM.todayCategoryMinutes.isEmpty {
                Text("Noch keine Eintraege")
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(statsVM.todayCategoryMinutes, id: \.category) { item in
                    categoryRow(item.category, minutes: item.minutes)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func categoryRow(_ category: ActivityCategory, minutes: Int) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(category.color.opacity(0.8))
                .frame(width: CGFloat(min(120, max(8, Double(minutes) / Double(max(1, statsVM.todayTotalMinutes)) * 120))), height: 12)

            Text(category.displayName)
                .font(.system(size: 11))
                .foregroundStyle(ThemeColors.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(StatisticsViewModel.formatMinutes(minutes))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeColors.textSecondary)

            Text("\(Int(statsVM.percentage(for: minutes)))%")
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textTertiary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("vs. 7-Tage-Ø")
                    .font(.system(size: 9))
                    .foregroundStyle(ThemeColors.textTertiary)
                Text("Score \(statsVM.weeklyAverageFocusScore)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ThemeColors.textPrimary)
            }

            Spacer()

            StreakBadge(days: statsVM.productiveStreak, label: "Produktiv")

            if let best = statsVM.bestHour {
                VStack(spacing: 1) {
                    Text("Best")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text(StatisticsViewModel.formatHour(best))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(ThemeColors.textPrimary)
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
                        .padding(.vertical, 6)
                        .background(ThemeColors.accent.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ThemeColors.accent.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(ThemeColors.accent)

                Button(action: onOpenStatistics) {
                    Label("Statistiken", systemImage: "chart.bar")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(ThemeColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(ThemeColors.textPrimary)
            }

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
            .foregroundStyle(ThemeColors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
