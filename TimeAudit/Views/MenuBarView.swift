import SwiftUI
import SwiftData

// MARK: - Menu Bar View

/// Main view shown in the MenuBarExtra popover. Displays today's summary with quick actions.
struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.timestamp, order: .reverse) private var allEntries: [TimeEntry]

    @Bindable var statsVM: StatisticsViewModel
    @Bindable var timerVM: TimerViewModel
    let identityProvider: IdentityProvider
    let settingsVM: SettingsViewModel
    let gameVM: GameViewModel
    let onLogNow: () -> Void
    let onOpenStatistics: () -> Void
    let onOpenSettings: () -> Void

    private var todayEntries: [TimeEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDateInToday($0.timestamp) }
    }

    private var goalMinutes: Int {
        settingsVM.useAdaptiveGoal ? statsVM.adaptiveGoalMinutes : settingsVM.dailyGoalMinutes
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                headerSection

                separator

                gardenAndScoreSection

                separator

                rpgSection

                separator

                todaySection

                separator

                missionBarSection

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

            // Achievement / Level-up toast overlay
            if gameVM.recentUnlock != nil || gameVM.showLevelUp {
                AchievementToastView(gameVM: gameVM)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: gameVM.recentUnlock?.achievementId)
                    .animation(.spring(response: 0.4), value: gameVM.showLevelUp)
            }
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

    // MARK: - Garden & Score

    private var gardenAndScoreSection: some View {
        HStack(spacing: 12) {
            GardenView(
                score: statsVM.todayFocusScore,
                isFaithMode: identityProvider.mode == .faith,
                size: .medium
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(identityProvider.scoreName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ThemeColors.textTertiary)
                Text("\(statsVM.todayFocusScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)

                DailyImpulseView(identityProvider: identityProvider, compact: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        let s = statsVM.todayFocusScore
        if s >= 75 { return .green }
        if s >= 50 { return ThemeColors.accent }
        if s >= 25 { return .orange }
        return .red
    }

    // MARK: - RPG Section

    private var rpgSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(ThemeColors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(gameVM.playerProfile?.level ?? 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Level title
                    Text(gameVM.playerProfile?.currentLevelTitle ?? "Anfänger")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ThemeColors.textPrimary)

                    // XP progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ThemeColors.elevatedBackground)
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ThemeColors.accent)
                                .frame(width: geo.size.width * CGFloat(gameVM.playerProfile?.levelProgress ?? 0), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                // Gold
                HStack(spacing: 3) {
                    Text("🪙")
                        .font(.system(size: 11))
                    Text("\(gameVM.playerProfile?.gold ?? 0)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.yellow)
                }
            }

            // Energy bar
            HStack(spacing: 6) {
                Text("⚡")
                    .font(.system(size: 10))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ThemeColors.elevatedBackground)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(gameVM.energyColor)
                            .frame(width: geo.size.width * CGFloat(gameVM.playerProfile?.energy ?? 100) / 100.0, height: 4)
                    }
                }
                .frame(height: 4)
                Text("\(gameVM.playerProfile?.energy ?? 100)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(ThemeColors.textTertiary)
                    .frame(width: 24, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

            Text(identityProvider.categoryName(for: category))
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

    // MARK: - Mission Bar

    private var missionBarSection: some View {
        MissionBar(
            currentMinutes: statsVM.todayProductiveMinutes,
            goalMinutes: goalMinutes,
            label: identityProvider.missionBarLabel(
                units: statsVM.todayProductiveMinutes / 15,
                goal: goalMinutes / 15
            ),
            compact: true
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("vs. 7-Tage-Ø")
                    .font(.system(size: 9))
                    .foregroundStyle(ThemeColors.textTertiary)
                Text("\(identityProvider.scoreName) \(statsVM.weeklyAverageFocusScore)")
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
