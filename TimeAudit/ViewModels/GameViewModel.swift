import Foundation
import SwiftUI
import SwiftData
import Observation

// MARK: - GameViewModel

/// Central RPG state management. Holds PlayerProfile, tracks achievements,
/// triggers level-up and unlock notifications.
@Observable
final class GameViewModel {

    var playerProfile: PlayerProfile?
    var achievements: [Achievement] = []

    // Toast / notification state
    var recentUnlock: Achievement?
    var showLevelUp: Bool = false
    var levelUpTitle: String = ""

    // MARK: - Initialization

    /// Creates or loads PlayerProfile and predefined achievements in SwiftData.
    func initializeIfNeeded(context: ModelContext) {
        // Load or create PlayerProfile (singleton)
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        if let profiles = try? context.fetch(profileDescriptor), let profile = profiles.first {
            self.playerProfile = profile
        } else {
            let profile = PlayerProfile()
            context.insert(profile)
            try? context.save()
            self.playerProfile = profile
        }

        // Load or create predefined achievements
        let achDescriptor = FetchDescriptor<Achievement>()
        if let existing = try? context.fetch(achDescriptor), !existing.isEmpty {
            self.achievements = existing
        } else {
            let predefined = Achievement.predefinedAchievements()
            predefined.forEach { context.insert($0) }
            try? context.save()
            self.achievements = predefined
        }
    }

    // MARK: - Process Entry

    /// Called after each log save. Updates XP, gold, energy, streak and checks achievements.
    /// Skipped on weekends – entries are recorded but don't affect score/XP/gold/energy/streak.
    func processEntry(category: ActivityCategory, minutes: Int, allEntries: [TimeEntry], context: ModelContext) {
        guard let profile = playerProfile else { return }
        guard StatisticsViewModel.isWorkday() else { return }

        // Update streak based on today vs last active date
        _ = GameEngine.shared.updateStreak(profile: profile, today: Date())

        // Apply XP / gold / energy – returns true if level-up occurred
        let leveledUp = GameEngine.shared.applyEntry(category: category, minutes: minutes, to: profile)

        // Check which achievements should now be unlocked
        let newIds = GameEngine.shared.checkAchievements(
            profile: profile,
            totalEntries: allEntries.count,
            entries: allEntries
        )

        for id in newIds {
            if let ach = achievements.first(where: { $0.achievementId == id && !$0.isUnlocked }) {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
                // Grant XP + gold rewards
                profile.xp += ach.xpReward
                profile.gold = max(0, profile.gold + ach.goldReward)

                // Show toast for first unlocked achievement (queue additional ones)
                if recentUnlock == nil {
                    showUnlockToast(ach)
                }
            }
        }

        // Level-up notification
        if leveledUp {
            levelUpTitle = profile.currentLevelTitle
            showLevelUp = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                self?.showLevelUp = false
            }
        }

        // Update companion mood based on recent behavior
        AICompanion.shared.updateMood(profile: profile, recentEntries: Array(allEntries.prefix(5)))

        try? context.save()
    }

    // MARK: - Helpers

    private func showUnlockToast(_ achievement: Achievement) {
        recentUnlock = achievement
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.recentUnlock = nil
        }
    }

    var levelProgressPercent: Int {
        Int((playerProfile?.levelProgress ?? 0) * 100)
    }

    /// Remaining Distraction Debt in minutes (0 = debt-free).
    var debtMinutes: Int { playerProfile?.debtMinutes ?? 0 }

    /// True when 3+ consecutive productive entries have been logged (1.5× XP active).
    var isInFlowState: Bool {
        (playerProfile?.consecutiveProductiveEntries ?? 0) >= 3
    }

    var energyColor: Color {
        let e = playerProfile?.energy ?? 100
        if e >= 70 { return .green }
        if e >= 40 { return .yellow }
        if e >= 20 { return .orange }
        return .red
    }
}
