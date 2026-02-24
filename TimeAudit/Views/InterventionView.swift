import SwiftUI

// MARK: - Intervention View

/// Loop-Breaker popup shown when 2 consecutive harmful logs are detected.
/// Offers a 1-minute breathing/prayer timer to break the negative pattern.
struct InterventionView: View {
    @Bindable var interventionVM: InterventionViewModel
    let identityProvider: IdentityProvider
    let onDismiss: () -> Void

    @State private var breathingPhase: Double = 0

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
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text(identityProvider.interventionTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.top, 28)
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: 16) {
            Text(identityProvider.interventionMessage)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Visual indicator of consecutive harmful logs
            HStack(spacing: 8) {
                ForEach(0..<interventionVM.consecutiveHarmfulCount, id: \.self) { _ in
                    Circle()
                        .fill(.red.opacity(0.6))
                        .frame(width: 10, height: 10)
                }
            }

            Text("\(interventionVM.consecutiveHarmfulCount)x hintereinander")
                .font(.system(size: 11))
                .foregroundStyle(.red.opacity(0.7))
        }
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
                Button(action: {
                    interventionVM.startTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: identityProvider.mode == .faith ? "hands.sparkles" : "wind")
                        Text(identityProvider.interventionActionLabel)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.5), .purple.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                interventionVM.dismiss()
                onDismiss()
            }) {
                Text("Ueberspringen")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
