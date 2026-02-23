import SwiftUI

// MARK: - Category Button

/// A single category selection button with shortcut label and color indicator.
/// Clicking saves immediately (when enabled).
struct CategoryButton: View {
    let category: ActivityCategory
    let isSelected: Bool
    let isSuggested: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Shortcut key badge
                Text(category.shortcutKey)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(isEnabled ? ThemeColors.textSecondary : ThemeColors.textTertiary)
                    .frame(width: 22, height: 22)
                    .background(ThemeColors.elevatedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                // Category icon
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(isEnabled ? category.color : category.color.opacity(0.35))
                    .frame(width: 20)

                // Category name
                Text(category.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isEnabled ? ThemeColors.textPrimary : ThemeColors.textTertiary)

                Spacer()

                // Suggestion indicator
                if isSuggested {
                    Text("vorgeschlagen")
                        .font(.system(size: 9))
                        .foregroundStyle(ThemeColors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ThemeColors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Color dot
                Circle()
                    .fill(isEnabled ? category.color : category.color.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? category.color.opacity(0.2) : ThemeColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
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
