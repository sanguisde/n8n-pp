import SwiftUI

// MARK: - Streak Badge

/// Displays the current streak count with a flame icon.
struct StreakBadge: View {
    let days: Int
    let label: String

    init(days: Int, label: String = "Streak") {
        self.days = days
        self.label = label
    }

    var body: some View {
        HStack(spacing: 4) {
            if days > 0 {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12))
            }
            Text("\(days) \(days == 1 ? "Tag" : "Tage")")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(days > 0 ? .orange : ThemeColors.textTertiary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(days > 0 ? Color.orange.opacity(0.12) : ThemeColors.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(days > 0 ? Color.orange.opacity(0.25) : ThemeColors.subtleBorder, lineWidth: 0.5)
        )
    }
}
