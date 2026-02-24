import SwiftUI
import SwiftData

// MARK: - Morning Intention View

/// Shown once per day after 8:00 AM (first app launch).
/// Forces the user to commit to 3 priorities and one thing to avoid.
struct MorningIntentionView: View {
    @Environment(\.modelContext) private var modelContext

    let intentionVM: IntentionViewModel
    let onDone: () -> Void

    @State private var priority1: String = ""
    @State private var priority2: String = ""
    @State private var priority3: String = ""
    @State private var avoidance: String = ""

    @FocusState private var focusedField: Field?

    enum Field { case p1, p2, p3, avoid }

    // Light theme
    private let bg          = Color(red: 0.97, green: 0.97, blue: 0.99)
    private let cardBg      = Color.white
    private let border      = Color(red: 0.85, green: 0.85, blue: 0.92)
    private let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.15)
    private let textSec     = Color(red: 0.40, green: 0.40, blue: 0.50)
    private let accent      = Color(red: 0.30, green: 0.40, blue: 0.95)

    private var canSubmit: Bool {
        !priority1.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    prioritiesSection
                    avoidanceSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 400, height: 480)
        .background(bg)
        .onAppear { focusedField = .p1 }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("🌅 Guten Morgen!")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(textPrimary)
            Text("Was sind deine Top-Prioritäten für heute?")
                .font(.system(size: 12))
                .foregroundStyle(textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(bg)
    }

    // MARK: - Priorities

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Meine 3 Prioritäten", systemImage: "checkmark.square.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)

            intentionField(
                placeholder: "Priorität 1 (wichtigste Aufgabe) *",
                text: $priority1,
                field: .p1,
                next: .p2,
                index: 1
            )
            intentionField(
                placeholder: "Priorität 2",
                text: $priority2,
                field: .p2,
                next: .p3,
                index: 2
            )
            intentionField(
                placeholder: "Priorität 3",
                text: $priority3,
                field: .p3,
                next: .avoid,
                index: 3
            )
        }
    }

    // MARK: - Avoidance

    private var avoidanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Was meide ich heute aktiv?", systemImage: "xmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 4)

                TextField("z.B. Instagram, aimless surfing, Slack-Rabbit-holes…", text: $avoidance)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(textPrimary)
                    .focused($focusedField, equals: .avoid)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
            )

            Text("Klare Commitments schlagen vage Vorsätze.")
                .font(.system(size: 10))
                .foregroundStyle(textSec)
                .italic()
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Später") {
                intentionVM.dismissMorning()
                onDone()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(textSec)

            Spacer()

            Button {
                save()
            } label: {
                Label("Tag starten", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canSubmit ? accent : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(bg)
    }

    // MARK: - Helpers

    private func intentionField(
        placeholder: String,
        text: Binding<String>,
        field: Field,
        next: Field,
        index: Int
    ) -> some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(index == 1 ? accent : (text.wrappedValue.isEmpty ? Color.gray.opacity(0.3) : accent.opacity(0.6)))
                .clipShape(Circle())

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(textPrimary)
                .focused($focusedField, equals: field)
                .onSubmit { focusedField = next }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focusedField == field ? accent.opacity(0.5) : border, lineWidth: 1)
                )
        )
    }

    private func save() {
        intentionVM.createIntention(
            priority1: priority1.trimmingCharacters(in: .whitespaces),
            priority2: priority2.trimmingCharacters(in: .whitespaces),
            priority3: priority3.trimmingCharacters(in: .whitespaces),
            avoidance: avoidance.trimmingCharacters(in: .whitespaces),
            context: modelContext
        )
        onDone()
    }
}
