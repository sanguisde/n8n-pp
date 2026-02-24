import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var achievementId: String
    var name: String
    var achievementDescription: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var xpReward: Int
    var goldReward: Int

    init(
        achievementId: String,
        name: String,
        achievementDescription: String,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        xpReward: Int = 0,
        goldReward: Int = 0
    ) {
        self.achievementId = achievementId
        self.name = name
        self.achievementDescription = achievementDescription
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.xpReward = xpReward
        self.goldReward = goldReward
    }

    /// All predefined achievements in their locked state.
    static func predefinedAchievements() -> [Achievement] {
        GameModels.achievementDefinitions.map { def in
            Achievement(
                achievementId: def.id,
                name: def.name,
                achievementDescription: def.description,
                xpReward: def.xpReward,
                goldReward: def.goldReward
            )
        }
    }
}
