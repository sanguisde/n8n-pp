import SwiftUI
import SwiftData

// MARK: - Logging Popup View

/// The main popup shown every 15 minutes. User must select a category before it can be dismissed.
struct LoggingPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var loggingVM: LoggingViewModel
    let intervalMinutes: Int
    let onSave: () -> Void

    @FocusState private var isNoteFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()
                .background(Color.white.opacity(0.1))

            // Category list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(ActivityCategory.allCases) { category in
                        CategoryButton(
                            category: category,
                            isSelected: loggingVM.selectedCategory == category,
                            isSuggested: loggingVM.suggestedCategory == category
                        ) {
                            loggingVM.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Project and note fields
            inputFields

            // Save button
            saveButton
        }
        .frame(width: 360, height: 540)
        .background(Color(NSColor.windowBackgroundColor))
        .preferredColorScheme(.dark)
        .onKeyPress(keys: Set("1234567890-".map { KeyEquivalent(Character(String($0))) })) { press in
            loggingVM.selectByShortcut(String(press.key.character))
            return .handled
        }
        .onKeyPress(.return) {
            if loggingVM.selectedCategory != nil {
                save()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            Text("Was hast du die letzten \(intervalMinutes) Min gemacht?")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Input Fields

    private var inputFields: some View {
        VStack(spacing: 8) {
            // Project tag
            HStack {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                TextField("Projekt (optional)", text: $loggingVM.projectText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Note
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                TextField("Notiz (optional)", text: $loggingVM.noteText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isNoteFieldFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Speichern")
                    .font(.system(size: 13, weight: .semibold))
                Text("(\u{23CE})")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                loggingVM.selectedCategory != nil
                    ? loggingVM.selectedCategory!.color.opacity(0.8)
                    : Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(loggingVM.selectedCategory == nil)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func save() {
        if loggingVM.saveEntry(context: modelContext, intervalMinutes: intervalMinutes) {
            onSave()
        }
    }
}
