import SwiftUI

// MARK: - Achievement Toast View

/// Shown briefly over the MenuBarView when an achievement is unlocked or a level-up occurs.
struct AchievementToastView: View {
    let gameVM: GameViewModel

    var body: some View {
        HStack(spacing: 10) {
            if gameVM.showLevelUp {
                levelUpContent
            } else if let unlock = gameVM.recentUnlock {
                achievementContent(unlock)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.accent.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        )
        .padding(.horizontal, 12)
    }

    private var levelUpContent: some View {
        HStack(spacing: 10) {
            Text("⬆️")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                Text("Level Up!")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ThemeColors.accent)
                Text("Du bist jetzt: \(gameVM.levelUpTitle)")
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            Spacer()

            Text("Lv. \(gameVM.playerProfile?.level ?? 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ThemeColors.accent.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func achievementContent(_ achievement: Achievement) -> some View {
        HStack(spacing: 10) {
            Text("🏆")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.yellow)
                Text(achievement.achievementDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("+\(achievement.xpReward) XP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ThemeColors.accent)
                Text("+\(achievement.goldReward) 🪙")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.yellow)
            }
        }
    }
}
