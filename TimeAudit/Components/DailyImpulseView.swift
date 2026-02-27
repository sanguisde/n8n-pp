import SwiftUI

// MARK: - Daily Impulse View

/// Displays a daily motivational quote (standard mode) or Bible verse (faith mode).
/// Changes daily using a date-based seed from IdentityProvider.
struct DailyImpulseView: View {
    let identityProvider: IdentityProvider
    var compact: Bool = false

    var body: some View {
        let impulse = identityProvider.dailyImpulse()

        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text("\"\(impulse.text)\"")
                .font(.system(size: compact ? 9 : 11))
                .foregroundStyle(ThemeColors.textSecondary)
                .italic()
                .lineLimit(compact ? 2 : 3)

            Text("— \(impulse.source)")
                .font(.system(size: compact ? 8 : 10, weight: .medium))
                .foregroundStyle(ThemeColors.textTertiary)
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(ThemeColors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
        )
    }
}
