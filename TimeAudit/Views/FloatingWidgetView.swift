import SwiftUI
import SwiftData

// MARK: - Floating Widget View

/// Compact always-on-top widget for quick time logging.
/// Light design with strong shadow for visibility on any desktop.
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

    // Light theme colors
    private let bg = Color(red: 0.97, green: 0.97, blue: 0.99)
    private let cardBg = Color.white
    private let border = Color(red: 0.85, green: 0.85, blue: 0.92)
    private let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.15)
    private let textSecondary = Color(red: 0.40, green: 0.40, blue: 0.50)
    private let accent = Color(red: 0.30, green: 0.40, blue: 0.95)

    var body: some View {
        ZStack {
            // Light background with colored top border accent
            RoundedRectangle(cornerRadius: 14)
                .fill(bg)
                .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(border, lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Colored accent bar at top
                accentTopBar

                headerRow
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                divider

                noteSection
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

                divider

                categoryButtons
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                    .padding(.top, 6)
            }
            .overlay(confirmationOverlay)
        }
        .frame(width: 260)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Accent Bar

    private var accentTopBar: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [accent, accent.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .clipShape(
                .rect(topLeadingRadius: 14, topTrailingRadius: 14)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(border)
            .frame(height: 0.5)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Nächstes Log")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(textSecondary)
                Text(timerLabel)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(identityProvider.scoreName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(textSecondary)
                HStack(spacing: 4) {
                    Text("\(statsVM.todayFocusScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Circle()
                        .fill(scoreColor)
                        .frame(width: 8, height: 8)
                }
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
        if secs > 300 { return textPrimary }
        if secs > 60  { return .orange }
        return .red
    }

    private var scoreColor: Color {
        let s = statsVM.todayFocusScore
        if s >= 75 { return Color(red: 0.1, green: 0.7, blue: 0.3) }
        if s >= 50 { return accent }
        if s >= 25 { return .orange }
        return .red
    }

    // MARK: - Note Input

    private var noteSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil.line")
                .font(.system(size: 12))
                .foregroundStyle(noteIsValid ? accent : textSecondary.opacity(0.5))

            TextField("Was hast du gemacht? *", text: $noteText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(textPrimary)
                .focused($isNoteFocused)
                .offset(x: noteShake ? -5 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: noteShake)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            noteShake ? Color.red.opacity(0.6) :
                            (noteIsValid ? accent.opacity(0.5) : border),
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
                    .foregroundStyle(noteIsValid ? .white : textSecondary.opacity(0.4))
                    .frame(width: 22, height: 22)
                    .background(noteIsValid ? category.color : Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                // Icon + Name
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(noteIsValid ? category.color : Color.gray.opacity(0.4))
                    .frame(width: 16)

                Text(identityProvider.categoryName(for: category))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(noteIsValid ? textPrimary : textSecondary.opacity(0.4))

                Spacer()

                // Color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(noteIsValid ? category.color : Color.gray.opacity(0.2))
                    .frame(width: 4, height: 22)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(noteIsValid ? category.color.opacity(0.06) : Color.gray.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                noteIsValid ? category.color.opacity(0.25) : border.opacity(0.5),
                                lineWidth: 1
                            )
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
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(cat.color)
                    Text(identityProvider.categoryName(for: cat))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textPrimary)
                    Text("Gespeichert")
                        .font(.system(size: 10))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bg.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
