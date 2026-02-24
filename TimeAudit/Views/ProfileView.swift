import SwiftUI

// MARK: - Profile View

/// RPG profile tab shown in StatisticsView. Displays level, XP, gold, energy,
/// streak, companion mood, and the achievement grid.
struct ProfileView: View {
    let gameVM: GameViewModel
    let identityProvider: IdentityProvider

    private var profile: PlayerProfile? { gameVM.playerProfile }

    var body: some View {
        VStack(spacing: 16) {
            playerCard
            achievementGrid
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Player Card

    private var playerCard: some View {
        VStack(spacing: 12) {
            // Avatar row
            HStack(spacing: 14) {
                avatarBadge
                playerStats
                Spacer()
                companionMoodBadge
            }

            // XP bar
            xpBar

            // Energy + Gold row
            HStack(spacing: 16) {
                energyBar
                Spacer()
                goldDisplay
                streakDisplay
            }
        }
        .padding(14)
        .background(ThemeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ThemeColors.subtleBorder, lineWidth: 0.5)
        )
    }

    private var avatarBadge: some View {
        ZStack {
            Circle()
                .fill(ThemeColors.accent.opacity(0.2))
                .frame(width: 56, height: 56)
            VStack(spacing: 0) {
                Text("\(profile?.level ?? 1)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.accent)
                Text("LVL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(ThemeColors.textTertiary)
            }
        }
    }

    private var playerStats: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(profile?.currentLevelTitle ?? "Anfänger")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)

            Text("\(profile?.xp ?? 0) XP")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ThemeColors.textSecondary)

            if profile?.streakShieldActive == true {
                Label("Streak-Schutz aktiv", systemImage: "shield.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var companionMoodBadge: some View {
        VStack(spacing: 4) {
            Text(profile?.companionMood.emoji ?? "😐")
                .font(.system(size: 28))
            Text(profile?.companionMood.rawValue.capitalized ?? "Neutral")
                .font(.system(size: 9))
                .foregroundStyle(ThemeColors.textTertiary)
        }
    }

    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("XP zum nächsten Level")
                    .font(.system(size: 10))
                    .foregroundStyle(ThemeColors.textTertiary)
                Spacer()
                Text("\(gameVM.levelProgressPercent)%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(ThemeColors.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ThemeColors.elevatedBackground)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.accent, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(profile?.levelProgress ?? 0), height: 7)
                }
            }
            .frame(height: 7)
        }
    }

    private var energyBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("⚡")
                    .font(.system(size: 11))
                Text("Energie")
                    .font(.system(size: 10))
                    .foregroundStyle(ThemeColors.textTertiary)
                Spacer()
                Text("\(profile?.energy ?? 100)/100")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(gameVM.energyColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ThemeColors.elevatedBackground)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gameVM.energyColor)
                        .frame(width: geo.size.width * CGFloat(profile?.energy ?? 100) / 100.0, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
    }

    private var goldDisplay: some View {
        VStack(spacing: 2) {
            Text("🪙")
                .font(.system(size: 20))
            Text("\(profile?.gold ?? 0)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.yellow)
            Text("Gold")
                .font(.system(size: 9))
                .foregroundStyle(ThemeColors.textTertiary)
        }
    }

    private var streakDisplay: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text("🔥")
                    .font(.system(size: 20))
                if profile?.streakShieldActive == true {
                    Text("🛡️")
                        .font(.system(size: 14))
                }
            }
            Text("\(profile?.streakDays ?? 0)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.orange)
            Text("Streak")
                .font(.system(size: 9))
                .foregroundStyle(ThemeColors.textTertiary)
        }
    }

    // MARK: - Achievement Grid

    private var achievementGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Achievements")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ThemeColors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(gameVM.achievements, id: \.achievementId) { achievement in
                    achievementCard(achievement)
                }
            }
        }
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(achievement.isUnlocked ? "🏆" : "🔒")
                    .font(.system(size: 18))
                Spacer()
                if achievement.isUnlocked {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("+\(achievement.xpReward) XP")
                            .font(.system(size: 9))
                            .foregroundStyle(ThemeColors.accent)
                        Text("+\(achievement.goldReward) 🪙")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.yellow)
                    }
                }
            }

            Text(achievement.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(achievement.isUnlocked ? ThemeColors.textPrimary : ThemeColors.textTertiary)
                .lineLimit(1)

            Text(achievement.achievementDescription)
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textTertiary)
                .lineLimit(2)

            if achievement.isUnlocked, let date = achievement.unlockedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 9))
                    .foregroundStyle(ThemeColors.textTertiary.opacity(0.6))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(achievement.isUnlocked ? ThemeColors.cardBackground : ThemeColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    achievement.isUnlocked ? Color.yellow.opacity(0.3) : ThemeColors.subtleBorder,
                    lineWidth: achievement.isUnlocked ? 1 : 0.5
                )
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.5)
    }
}
