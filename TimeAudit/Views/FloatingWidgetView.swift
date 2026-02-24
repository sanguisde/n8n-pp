import SwiftUI
import SwiftData

// MARK: - Floating Widget View

/// Compact always-on-top widget for quick time logging.
/// Includes day blocks, daily impulse, mission bar, and category buttons.
struct FloatingWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.timestamp, order: .reverse) private var allEntries: [TimeEntry]

    @Bindable var timerVM: TimerViewModel
    @Bindable var statsVM: StatisticsViewModel
    @Bindable var settingsVM: SettingsViewModel
    let identityProvider: IdentityProvider

    @State private var noteText: String = ""
    @State private var savedCategory: ActivityCategory?
    @State private var showConfirmation: Bool = false
    @State private var noteShake: Bool = false
    @FocusState private var isNoteFocused: Bool

    private var noteIsValid: Bool {
        !noteText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var todayEntries: [TimeEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDateInToday($0.timestamp) }
    }

    private var goalMinutes: Int {
        settingsVM.useAdaptiveGoal ? statsVM.adaptiveGoalMinutes : settingsVM.dailyGoalMinutes
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: Timer + Score
            headerRow
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)

            separator

            // Day blocks timeline
            DayBlocksView(entries: todayEntries, intervalMinutes: settingsVM.intervalMinutes, compact: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            // Mission bar
            MissionBar(
                currentMinutes: statsVM.todayProductiveMinutes,
                goalMinutes: goalMinutes,
                label: identityProvider.missionBarLabel(
                    units: statsVM.todayProductiveMinutes / 15,
                    goal: goalMinutes / 15
                ),
                compact: true
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            separator

            // Note input (mandatory)
            noteRow
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            separator

            // Category buttons (3 in a row)
            categoryRow
                .padding(.horizontal, 6)
                .padding(.vertical, 4)

            separator

            // Daily impulse
            DailyImpulseView(identityProvider: identityProvider, compact: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .frame(width: 260)
        .overlay(confirmationOverlay)
    }

    private var separator: some View {
        Rectangle()
            .fill(ThemeColors.subtleBorder)
            .frame(height: 0.5)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 6) {
            GardenMenuBarIcon(score: statsVM.todayFocusScore)

            Text(timerLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeColors.textSecondary)

            Spacer()

            Text(identityProvider.scoreName)
                .font(.system(size: 8))
                .foregroundStyle(ThemeColors.textTertiary)
            Text("\(statsVM.todayFocusScore)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
        }
    }

    private var timerLabel: String {
        let min = timerVM.secondsRemaining / 60
        let sec = timerVM.secondsRemaining % 60
        return "\(min):\(String(format: "%02d", sec))"
    }

    private var scoreColor: Color {
        let s = statsVM.todayFocusScore
        if s >= 75 { return .green }
        if s >= 50 { return ThemeColors.accent }
        if s >= 25 { return .orange }
        return .red
    }

    // MARK: - Note Row

    private var noteRow: some View {
        VStack(spacing: 3) {
            TextField("Kommentar *", text: $noteText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(ThemeColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            noteShake ? ThemeColors.dangerAccent : (noteIsValid ? ThemeColors.accent.opacity(0.3) : ThemeColors.subtleBorder),
                            lineWidth: noteShake ? 1.5 : 0.5
                        )
                )
                .focused($isNoteFocused)
                .offset(x: noteShake ? -4 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: noteShake)

            if !noteIsValid {
                Text("Pflichtfeld")
                    .font(.system(size: 8))
                    .foregroundStyle(ThemeColors.dangerAccent.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
        }
    }

    // MARK: - Category Row

    private var categoryRow: some View {
        HStack(spacing: 4) {
            ForEach(ActivityCategory.allCases) { category in
                categoryIcon(category)
            }
        }
    }

    private func categoryIcon(_ category: ActivityCategory) -> some View {
        Button {
            if noteIsValid {
                logCategory(category)
            } else {
                triggerNoteShake()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 16))
                    .foregroundStyle(noteIsValid ? category.color : category.color.opacity(0.35))
                Text(category.shortcutKey)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(ThemeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help(identityProvider.categoryName(for: category))
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        Group {
            if showConfirmation, let cat = savedCategory {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text(identityProvider.categoryName(for: cat))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ThemeColors.background.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showConfirmation)
    }

    // MARK: - Actions

    private func logCategory(_ category: ActivityCategory) {
        let entry = TimeEntry(
            timestamp: .now,
            categoryValue: category.rawValue,
            note: noteText.trimmingCharacters(in: .whitespaces),
            intervalMinutes: settingsVM.intervalMinutes
        )
        modelContext.insert(entry)
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategoryValue")

        savedCategory = category
        showConfirmation = true
        noteText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showConfirmation = false
        }

        timerVM.didLog()

        let descriptor = FetchDescriptor<TimeEntry>()
        if let entries = try? modelContext.fetch(descriptor) {
            statsVM.refresh(entries: entries)
        }
    }

    private func triggerNoteShake() {
        noteShake = true
        isNoteFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            noteShake = false
        }
    }
}
