import SwiftUI

// MARK: - Category Button

/// A single category selection button with shortcut label and color indicator.
struct CategoryButton: View {
    let category: ActivityCategory
    let isSelected: Bool
    let isSuggested: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Shortcut key badge
                Text(category.shortcutKey)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Category icon
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(category.color)
                    .frame(width: 20)

                // Category name
                Text(category.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)

                Spacer()

                // Suggestion indicator
                if isSuggested {
                    Text("vorgeschlagen")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }

                // Color dot
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? category.color.opacity(0.3) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
