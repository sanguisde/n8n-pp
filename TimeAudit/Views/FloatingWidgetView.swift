import SwiftUI
import SwiftData

// MARK: - Floating Widget View

/// Compact always-on-top widget for quick time logging.
/// Note is mandatory - user types a note first, then clicks a category to save.
struct FloatingWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var timerVM: TimerViewModel
    @Bindable var statsVM: StatisticsViewModel
    @Bindable var settingsVM: SettingsViewModel

    @State private var noteText: String = ""
    @State private var savedCategory: ActivityCategory?
    @State private var showConfirmation: Bool = false
    @State private var noteShake: Bool = false
    @FocusState private var isNoteFocused: Bool

    private let topRow: [ActivityCategory] = [
        .revenueGenerating, .strategisch, .deepWork, .admin, .konsum, .ablenkung
    ]
    private let bottomRow: [ActivityCategory] = [
        .pause, .training, .schlaf, .beziehung, .sonstiges
    ]

    private var noteIsValid: Bool {
        !noteText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: Timer + Score
            headerRow
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)

            separator

            // Note input (mandatory, above categories)
            noteRow
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            separator

            // Category grid
            categoryGrid
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
        }
        .frame(width: 240)
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
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textTertiary)
            Text(timerLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeColors.textSecondary)

            Spacer()

            Text("Score")
                .font(.system(size: 9))
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
            HStack(spacing: 4) {
                TextField("Notiz *", text: $noteText)
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
            }
            if !noteIsValid {
                Text("Pflichtfeld")
                    .font(.system(size: 8))
                    .foregroundStyle(ThemeColors.dangerAccent.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(topRow) { category in
                    categoryIcon(category)
                }
            }
            HStack(spacing: 4) {
                ForEach(bottomRow) { category in
                    categoryIcon(category)
                }
                Spacer()
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
                    .font(.system(size: 14))
                    .foregroundStyle(noteIsValid ? category.color : category.color.opacity(0.35))
                Text(category.shortcutKey)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeColors.textTertiary)
            }
            .frame(width: 34, height: 34)
            .background(ThemeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help(category.rawValue)
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        Group {
            if showConfirmation, let cat = savedCategory {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text(cat.rawValue)
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
            category: category.rawValue,
            note: noteText.trimmingCharacters(in: .whitespaces),
            intervalMinutes: settingsVM.intervalMinutes
        )
        modelContext.insert(entry)
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategory")

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
