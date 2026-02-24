import SwiftUI

// MARK: - Intervention View

/// Micro-Intervention popup shown when 2 consecutive harmful logs are detected.
/// Asks for a next-task commitment and offers a breathing timer to break the pattern.
struct InterventionView: View {
    @Bindable var interventionVM: InterventionViewModel
    let identityProvider: IdentityProvider
    let onDismiss: () -> Void

    @State private var breathingPhase: Double = 0
    @FocusState private var nextTaskFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Warning header
            warningHeader

            Spacer()

            // Main content
            if interventionVM.interventionCompleted {
                completionView
            } else if interventionVM.isTimerRunning {
                timerView
            } else {
                promptView
            }

            Spacer()

            // Action buttons
            if !interventionVM.interventionCompleted {
                actionButtons
            }
        }
        .frame(width: 340, height: 380)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Warning Header

    private var warningHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<min(interventionVM.consecutiveHarmfulCount, 5), id: \.self) { _ in
                    Circle()
                        .fill(.red.opacity(0.7))
                        .frame(width: 8, height: 8)
                }
            }

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("Du bist im Ablenkungsmodus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Text("\(interventionVM.consecutiveHarmfulCount)× Ablenkung in Folge")
                .font(.system(size: 11))
                .foregroundStyle(.red.opacity(0.7))
        }
        .padding(.top, 24)
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: 14) {
            Text("Was machst du als nächstes?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            // Next-task commitment field
            TextField("Deine nächste konkrete Aufgabe…", text: $interventionVM.nextTaskText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .focused($nextTaskFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 24)

            Text(identityProvider.interventionMessage)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .onAppear { nextTaskFocused = true }
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 20) {
            // Breathing circle animation
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(interventionVM.timerSecondsRemaining) / 60.0)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: interventionVM.timerSecondsRemaining)

                Text("\(interventionVM.timerSecondsRemaining)")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(identityProvider.mode == .faith ? "Stille..." : "Atme tief ein und aus...")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text(identityProvider.mode == .faith ? "Moment der Umkehr abgeschlossen" : "Pause abgeschlossen")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)

            Text("Weiter geht's!")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            if !interventionVM.isTimerRunning {
                HStack(spacing: 10) {
                    // Primary: commit and log now
                    Button(action: {
                        interventionVM.dismiss()
                        onDismiss()
                    }) {
                        Label("Jetzt loggen", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.4, blue: 0.95), Color(red: 0.2, green: 0.3, blue: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])

                    // Secondary: breathing break
                    Button(action: {
                        interventionVM.startTimer()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: identityProvider.mode == .faith ? "hands.sparkles" : "wind")
                            Text(identityProvider.interventionActionLabel)
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: {
                interventionVM.dismiss()
                onDismiss()
            }) {
                Text("Überspringen")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
