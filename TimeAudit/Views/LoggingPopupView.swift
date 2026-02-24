import SwiftUI
import SwiftData

// MARK: - Theme Colors

/// Shared dark theme colors used across the app.
enum ThemeColors {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.15)
    static let elevatedBackground = Color(red: 0.14, green: 0.14, blue: 0.19)
    static let subtleBorder = Color.white.opacity(0.08)
    static let inputBackground = Color(red: 0.09, green: 0.09, blue: 0.13)
    static let accent = Color(red: 0.40, green: 0.50, blue: 1.0)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.50)
    static let textTertiary = Color.white.opacity(0.30)
    static let dangerAccent = Color(red: 1.0, green: 0.35, blue: 0.35)
}

// MARK: - Logging Popup View

/// The main popup shown every 15 minutes.
/// Flow: User enters a note (mandatory) -> clicks a category -> saves immediately.
struct LoggingPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var loggingVM: LoggingViewModel
    let intervalMinutes: Int
    let onSave: () -> Void

    @FocusState private var isNoteFieldFocused: Bool
    @State private var noteShake: Bool = false
    @State private var savedCategory: ActivityCategory?
    @State private var showConfirmation: Bool = false
    @State private var showNudge: Bool = false
    @State private var nudgeDismissed: Bool = false
    private let currentNudge: AppetitzerNudge = DopaminMenu.shared.randomNudge()

    private var noteIsValid: Bool {
        !loggingVM.noteText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            noteInputSection

            categorySection
        }
        .frame(width: 360, height: 400)
        .background(ThemeColors.background)
        .overlay(confirmationOverlay)
        .preferredColorScheme(.dark)
        .onKeyPress(keys: Set("123".map { KeyEquivalent(Character(String($0))) })) { press in
            let key = String(press.key.character)
            if let category = ActivityCategory.allCases.first(where: { $0.shortcutKey == key }) {
                if noteIsValid {
                    saveWithCategory(category)
                } else {
                    triggerNoteShake()
                }
            }
            return .handled
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(ThemeColors.accent)

            Text("Was hast du die letzten \(intervalMinutes) Min gemacht?")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(ThemeColors.textPrimary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Note Input

    private var noteInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundStyle(noteIsValid ? ThemeColors.accent : ThemeColors.dangerAccent)
                    .frame(width: 16)
                Text("Kommentar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(noteIsValid ? ThemeColors.textSecondary : ThemeColors.dangerAccent)
                Text("*")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ThemeColors.dangerAccent)
                Spacer()
            }

            TextField("Was genau hast du gemacht?", text: $loggingVM.noteText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ThemeColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            noteShake ? ThemeColors.dangerAccent : (noteIsValid ? ThemeColors.accent.opacity(0.4) : ThemeColors.subtleBorder),
                            lineWidth: noteShake ? 1.5 : 1
                        )
                )
                .focused($isNoteFieldFocused)
                .offset(x: noteShake ? -6 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: noteShake)

            if !noteIsValid {
                Text("Tipp erst einen kurzen Kommentar ein, dann klick die Kategorie")
                    .font(.system(size: 10))
                    .foregroundStyle(ThemeColors.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .onAppear {
            isNoteFieldFocused = true
        }
    }

    // MARK: - Category Buttons

    private var categorySection: some View {
        VStack(spacing: 8) {
            ForEach(ActivityCategory.allCases) { category in
                CategoryButton(
                    category: category,
                    isSelected: false,
                    isSuggested: loggingVM.suggestedCategory == category,
                    isEnabled: noteIsValid
                ) {
                    if noteIsValid {
                        // Show nudge when selecting harmful category
                        if category == .harmful && !nudgeDismissed {
                            withAnimation(.easeInOut(duration: 0.2)) { showNudge = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                                withAnimation { showNudge = false }
                            }
                        }
                        saveWithCategory(category)
                    } else {
                        triggerNoteShake()
                    }
                }
            }

            // Dopamin-Nudge – shown briefly after logging a harmful entry
            if showNudge {
                dopaminNudgeView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: showNudge)
    }

    private var dopaminNudgeView: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("💡")
                .font(.system(size: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text("Alternativ: \(currentNudge.alternative)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(currentNudge.durationMinutes) Min · \(currentNudge.benefit)")
                    .font(.system(size: 10))
                    .foregroundStyle(ThemeColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                nudgeDismissed = true
                withAnimation { showNudge = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(ThemeColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ThemeColors.elevatedBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        Group {
            if showConfirmation, let cat = savedCategory {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                    Text(cat.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Gespeichert")
                        .font(.system(size: 11))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ThemeColors.background.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showConfirmation)
    }

    // MARK: - Actions

    private func saveWithCategory(_ category: ActivityCategory) {
        loggingVM.selectedCategory = category

        if loggingVM.saveEntry(context: modelContext, intervalMinutes: intervalMinutes) {
            savedCategory = category
            showConfirmation = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showConfirmation = false
                onSave()
            }
        }
    }

    private func triggerNoteShake() {
        noteShake = true
        isNoteFieldFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            noteShake = false
        }
    }
}
