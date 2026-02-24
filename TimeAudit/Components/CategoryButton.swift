import SwiftUI

// MARK: - Category Button

/// A large category selection button with shortcut label and color indicator.
/// Designed for 3 categories - bigger and more prominent.
struct CategoryButton: View {
    let category: ActivityCategory
    let isSelected: Bool
    let isSuggested: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Shortcut key badge
                Text(category.shortcutKey)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(isEnabled ? ThemeColors.textSecondary : ThemeColors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(ThemeColors.elevatedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Category icon
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(isEnabled ? category.color : category.color.opacity(0.35))
                    .frame(width: 24)

                // Category name
                Text(category.displayName)
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isEnabled ? ThemeColors.textPrimary : ThemeColors.textTertiary)

                Spacer()

                // Suggestion indicator
                if isSuggested {
                    Text("vorgeschlagen")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ThemeColors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Color indicator bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(isEnabled ? category.color : category.color.opacity(0.35))
                    .frame(width: 4, height: 28)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? category.color.opacity(0.2) : ThemeColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? category.color.opacity(0.5) : ThemeColors.subtleBorder,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
