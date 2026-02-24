import SwiftUI
import SwiftData

// MARK: - Menu Bar View

/// Main view shown in the MenuBarExtra popover. Light design for readability.
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

    // Light theme colors
    private let bg          = Color(red: 0.97, green: 0.97, blue: 0.99)
    private let cardBg      = Color.white
    private let border      = Color(red: 0.85, green: 0.85, blue: 0.92)
    private let trackBg     = Color(red: 0.90, green: 0.90, blue: 0.94)
    private let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.15)
    private let textSec     = Color(red: 0.40, green: 0.40, blue: 0.50)
    private let textTer     = Color(red: 0.60, green: 0.60, blue: 0.68)
    private let accent      = Color(red: 0.30, green: 0.40, blue: 0.95)

    private var todayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var goalMinutes: Int {
        settingsVM.useAdaptiveGoal ? statsVM.adaptiveGoalMinutes : settingsVM.dailyGoalMinutes
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                headerSection
                divider
                gardenAndScoreSection
                divider
                rpgSection
                divider
                todaySection
                divider
                missionBarSection
                divider
                insightsSection
                divider
                actionsSection
            }
            .frame(width: 360)
            .background(bg)
            .onAppear { statsVM.refresh(entries: allEntries) }
            .onChange(of: allEntries.count) { statsVM.refresh(entries: allEntries) }

            // Achievement / level-up toast
            if gameVM.recentUnlock != nil || gameVM.showLevelUp {
                AchievementToastView(gameVM: gameVM)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4), value: gameVM.recentUnlock?.achievementId)
                    .animation(.spring(response: 0.4), value: gameVM.showLevelUp)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(border).frame(height: 0.5)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TimeAudit")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textPrimary)
                Text(timerLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(textSec)
            }
            Spacer()
            FocusScoreView(score: statsVM.todayFocusScore, size: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bg)
    }

    private var timerLabel: String {
        let min = timerVM.secondsRemaining / 60
        let sec = timerVM.secondsRemaining % 60
        return "Nächstes Log in \(min):\(String(format: "%02d", sec))"
    }

    // MARK: - Garden & Score

    private var gardenAndScoreSection: some View {
        HStack(spacing: 14) {
            GardenView(
                score: statsVM.todayFocusScore,
                isFaithMode: identityProvider.mode == .faith,
                size: .medium
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(identityProvider.scoreName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(textTer)
                Text("\(statsVM.todayFocusScore)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                DailyImpulseView(identityProvider: identityProvider, compact: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bg)
    }

    private var scoreColor: Color {
        let s = statsVM.todayFocusScore
        if s >= 75 { return Color(red: 0.1, green: 0.65, blue: 0.3) }
        if s >= 50 { return accent }
        if s >= 25 { return .orange }
        return .red
    }

    // MARK: - RPG Section

    private var rpgSection: some View {
        VStack(spacing: 7) {
            HStack(spacing: 10) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Text("\(gameVM.playerProfile?.level ?? 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(gameVM.playerProfile?.currentLevelTitle ?? "Anfänger")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(textPrimary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(trackBg)
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accent)
                                .frame(width: geo.size.width * CGFloat(gameVM.playerProfile?.levelProgress ?? 0), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                HStack(spacing: 3) {
                    Text("🪙")
                        .font(.system(size: 12))
                    Text("\(gameVM.playerProfile?.gold ?? 0)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.7, green: 0.5, blue: 0.0))
                }
            }

            // Energy bar
            HStack(spacing: 6) {
                Text("⚡")
                    .font(.system(size: 10))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(trackBg)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(gameVM.energyColor)
                            .frame(width: geo.size.width * CGFloat(gameVM.playerProfile?.energy ?? 100) / 100.0, height: 4)
                    }
                }
                .frame(height: 4)
                Text("\(gameVM.playerProfile?.energy ?? 100)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(textTer)
                    .frame(width: 24, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(bg)
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Heute")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(textSec)

            if statsVM.todayCategoryMinutes.isEmpty {
                Text("Noch keine Einträge")
                    .font(.system(size: 12))
                    .foregroundStyle(textTer)
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
        .background(bg)
    }

    private func categoryRow(_ category: ActivityCategory, minutes: Int) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(category.color.opacity(0.7))
                .frame(width: CGFloat(min(130, max(8, Double(minutes) / Double(max(1, statsVM.todayTotalMinutes)) * 130))), height: 11)

            Text(identityProvider.categoryName(for: category))
                .font(.system(size: 11))
                .foregroundStyle(textPrimary)
                .lineLimit(1)

            Spacer()

            Text(StatisticsViewModel.formatMinutes(minutes))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(textSec)

            Text("\(Int(statsVM.percentage(for: minutes)))%")
                .font(.system(size: 10))
                .foregroundStyle(textTer)
                .frame(width: 32, alignment: .trailing)
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
        Group {
            if !StatisticsViewModel.isWorkday() {
                HStack {
                    Text("🌴 Wochenende – kein Druck")
                        .font(.system(size: 11))
                        .foregroundStyle(textSec)
                    Spacer()
                }
            } else {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("vs. 7-Tage-Ø")
                            .font(.system(size: 9))
                            .foregroundStyle(textTer)
                        Text("\(identityProvider.scoreName) \(statsVM.weeklyAverageFocusScore)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(textPrimary)
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
                                .foregroundStyle(textPrimary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(bg)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(action: onLogNow) {
                    Label("Jetzt loggen", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Button(action: onOpenStatistics) {
                    Label("Statistiken", systemImage: "chart.bar")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .foregroundStyle(textPrimary)
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
            .foregroundStyle(textTer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bg)
    }
}
