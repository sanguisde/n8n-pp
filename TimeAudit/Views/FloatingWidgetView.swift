import SwiftUI
import SwiftData

// MARK: - Floating Widget View

/// Compact always-on-top widget for quick time logging.
/// Categories are always visible as icon buttons - one click to log.
struct FloatingWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var timerVM: TimerViewModel
    @Bindable var statsVM: StatisticsViewModel
    @Bindable var settingsVM: SettingsViewModel

    @State private var noteText: String = ""
    @State private var savedCategory: ActivityCategory?
    @State private var showConfirmation: Bool = false

    /// All categories split into two rows for compact grid
    private let topRow: [ActivityCategory] = [
        .revenueGenerating, .strategisch, .deepWork, .admin, .konsum, .ablenkung
    ]
    private let bottomRow: [ActivityCategory] = [
        .pause, .training, .schlaf, .beziehung, .sonstiges
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header: Timer + Score
            headerRow
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)

            Divider().opacity(0.3)

            // Category grid - always visible, one tap to log
            categoryGrid
                .padding(.horizontal, 6)
                .padding(.vertical, 6)

            Divider().opacity(0.3)

            // Note input + save
            noteRow
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(width: 240)
        .overlay(confirmationOverlay)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 6) {
            // Timer
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(timerLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

            // Focus Score
            Text("Score")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
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
        if s >= 50 { return .blue }
        if s >= 25 { return .orange }
        return .red
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
            logCategory(category)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(category.color)
                Text(category.shortcutKey)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(category.rawValue)
    }

    // MARK: - Note Row

    private var noteRow: some View {
        HStack(spacing: 4) {
            TextField("Notiz...", text: $noteText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
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
                .background(Color.black.opacity(0.75))
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
            note: noteText.isEmpty ? nil : noteText,
            intervalMinutes: settingsVM.intervalMinutes
        )
        modelContext.insert(entry)
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategory")

        // Show confirmation
        savedCategory = category
        showConfirmation = true
        noteText = ""

        // Hide confirmation after 0.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showConfirmation = false
        }

        // Reset timer since user just logged
        timerVM.didLog()

        // Refresh stats
        let descriptor = FetchDescriptor<TimeEntry>()
        if let entries = try? modelContext.fetch(descriptor) {
            statsVM.refresh(entries: entries)
        }
    }
}
