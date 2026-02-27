import SwiftUI
import SwiftData

// MARK: - Evening Debrief View

/// Shown at 17:30 to close out the day: checkbox priorities, biggest win, what to repeat.
struct EveningDebriefView: View {
    @Environment(\.modelContext) private var modelContext

    let intentionVM: IntentionViewModel
    let onDone: () -> Void

    @State private var priority1Done: Bool = false
    @State private var priority2Done: Bool = false
    @State private var priority3Done: Bool = false
    @State private var biggestWin: String = ""
    @State private var whatToRepeat: String = ""

    @FocusState private var focusedField: Field?
    enum Field { case win, repeat_ }

    // Light theme
    private let bg          = Color(red: 0.97, green: 0.97, blue: 0.99)
    private let cardBg      = Color.white
    private let border      = Color(red: 0.85, green: 0.85, blue: 0.92)
    private let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.15)
    private let textSec     = Color(red: 0.40, green: 0.40, blue: 0.50)
    private let accent      = Color(red: 0.30, green: 0.40, blue: 0.95)

    private var intention: DailyIntention? { intentionVM.todayIntention }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    prioritiesCheckSection
                    reflectionSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 400, height: 460)
        .background(bg)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("🌆 Tages-Debrief")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(textPrimary)
            Text("Wie war der Tag? Was hast du erreicht?")
                .font(.system(size: 12))
                .foregroundStyle(textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(bg)
    }

    // MARK: - Priorities Check

    private var prioritiesCheckSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Prioritäten erledigt?", systemImage: "checklist")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)

            if let i = intention {
                if !i.priority1.isEmpty {
                    priorityCheckRow(label: i.priority1, done: $priority1Done, color: .green)
                }
                if !i.priority2.isEmpty {
                    priorityCheckRow(label: i.priority2, done: $priority2Done, color: accent)
                }
                if !i.priority3.isEmpty {
                    priorityCheckRow(label: i.priority3, done: $priority3Done, color: .orange)
                }
            } else {
                Text("Keine Prioritäten gesetzt")
                    .font(.system(size: 12))
                    .foregroundStyle(textSec)
            }
        }
    }

    private func priorityCheckRow(label: String, done: Binding<Bool>, color: Color) -> some View {
        Button {
            done.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: done.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(done.wrappedValue ? color : Color.gray.opacity(0.4))
                    .animation(.spring(response: 0.2), value: done.wrappedValue)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(done.wrappedValue ? textSec : textPrimary)
                    .strikethrough(done.wrappedValue)
                    .lineLimit(2)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(done.wrappedValue ? color.opacity(0.05) : cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reflexion", systemImage: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.7, green: 0.5, blue: 0.0))

            VStack(alignment: .leading, spacing: 4) {
                Text("Größter Erfolg heute")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(textSec)
                TextField("Was lief richtig gut?", text: $biggestWin)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(textPrimary)
                    .focused($focusedField, equals: .win)
                    .onSubmit { focusedField = .repeat_ }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Morgen wiederholen")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(textSec)
                TextField("Was hat gut funktioniert?", text: $whatToRepeat)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(textPrimary)
                    .focused($focusedField, equals: .repeat_)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
                    )
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Später") {
                intentionVM.dismissEvening()
                onDone()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(textSec)

            Spacer()

            Button {
                intentionVM.completeDebrief(
                    priority1Done: priority1Done,
                    priority2Done: priority2Done,
                    priority3Done: priority3Done,
                    biggestWin: biggestWin.trimmingCharacters(in: .whitespaces),
                    whatToRepeat: whatToRepeat.trimmingCharacters(in: .whitespaces),
                    context: modelContext
                )
                onDone()
            } label: {
                Label("Tag abschließen", systemImage: "moon.stars.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(bg)
    }
}
