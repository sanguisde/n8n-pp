import SwiftUI
import SwiftData

// MARK: - Floating Widget View

/// Compact always-on-top widget for quick time logging.
/// Focused on the core action: note + category. Timer and score as context.
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

    var body: some View {
        ZStack {
            // Solid dark background for max visibility
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                Divider()
                    .background(Color.white.opacity(0.08))

                noteSection
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

                Divider()
                    .background(Color.white.opacity(0.08))

                categoryButtons
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .overlay(confirmationOverlay)
        }
        .frame(width: 260)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            // Countdown timer – urgent visual cue
            VStack(alignment: .leading, spacing: 1) {
                Text("Nächstes Log")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(timerLabel)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerColor)
            }

            Spacer()

            // Score pill
            HStack(spacing: 5) {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 7, height: 7)
                Text("\(statsVM.todayFocusScore)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text(identityProvider.scoreName)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private var timerLabel: String {
        let min = timerVM.secondsRemaining / 60
        let sec = timerVM.secondsRemaining % 60
        return "\(min):\(String(format: "%02d", sec))"
    }

    private var timerColor: Color {
        let secs = timerVM.secondsRemaining
        if secs > 300 { return Color.white.opacity(0.75) }
        if secs > 60  { return .orange }
        return .red
    }

    private var scoreColor: Color {
        let s = statsVM.todayFocusScore
        if s >= 75 { return .green }
        if s >= 50 { return Color(red: 0.4, green: 0.5, blue: 1.0) }
        if s >= 25 { return .orange }
        return .red
    }

    // MARK: - Note Input

    private var noteSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil")
                .font(.system(size: 11))
                .foregroundStyle(noteIsValid ? Color(red: 0.4, green: 0.5, blue: 1.0) : Color.white.opacity(0.25))

            TextField("Was hast du gemacht? *", text: $noteText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.90))
                .focused($isNoteFocused)
                .offset(x: noteShake ? -5 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: noteShake)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            noteShake ? Color.red.opacity(0.7) :
                            (noteIsValid ? Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.5) : Color.white.opacity(0.08)),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Category Buttons

    private var categoryButtons: some View {
        VStack(spacing: 5) {
            ForEach(ActivityCategory.allCases) { category in
                widgetCategoryButton(category)
            }
        }
    }

    private func widgetCategoryButton(_ category: ActivityCategory) -> some View {
        Button {
            if noteIsValid {
                logCategory(category)
            } else {
                triggerNoteShake()
                isNoteFocused = true
            }
        } label: {
            HStack(spacing: 10) {
                // Shortcut badge
                Text(category.shortcutKey)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Icon
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 13))
                    .foregroundStyle(noteIsValid ? category.color : category.color.opacity(0.3))
                    .frame(width: 18)

                // Name
                Text(identityProvider.categoryName(for: category))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(noteIsValid ? Color.white.opacity(0.85) : Color.white.opacity(0.3))

                Spacer()

                // Color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(noteIsValid ? category.color : category.color.opacity(0.2))
                    .frame(width: 3, height: 20)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(noteIsValid ? category.color.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(noteIsValid ? category.color.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .help(identityProvider.categoryName(for: category))
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        Group {
            if showConfirmation, let cat = savedCategory {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(cat.color)
                    Text(identityProvider.categoryName(for: cat))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Text("Gespeichert ✓")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.14).opacity(0.95))
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showConfirmation)
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            noteShake = false
        }
    }
}
