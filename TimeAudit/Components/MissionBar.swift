import SwiftUI

// MARK: - Mission Bar

/// Progress bar showing Category 1 (productive) progress toward the daily goal.
/// Supports both manual and adaptive goals with mode-dependent labeling.
struct MissionBar: View {
    /// Current productive minutes today
    let currentMinutes: Int
    /// Goal minutes (manual or adaptive)
    let goalMinutes: Int
    /// Label text from IdentityProvider
    let label: String
    /// Whether to show compact version (widget)
    var compact: Bool = false

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1.0, Double(currentMinutes) / Double(goalMinutes))
    }

    private var progressColor: Color {
        if progress >= 0.9 { return .green }
        if progress >= 0.6 { return .orange }
        if progress >= 0.3 { return .yellow }
        return .red
    }

    private var currentUnits: Int {
        currentMinutes / 15
    }

    private var goalUnits: Int {
        goalMinutes / 15
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            // Label
            Text(label)
                .font(.system(size: compact ? 9 : 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: compact ? 3 : 4)
                        .fill(ThemeColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: compact ? 3 : 4)
                                .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
                        )

                    // Progress fill
                    RoundedRectangle(cornerRadius: compact ? 3 : 4)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.6), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: compact ? 6 : 8)

            // Percentage label
            if !compact {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(progressColor)
                    Spacer()
                    Text("\(StatisticsViewModel.formatMinutes(currentMinutes)) / \(StatisticsViewModel.formatMinutes(goalMinutes))")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.textTertiary)
                }
            }
        }
    }
}
