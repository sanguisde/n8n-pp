import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var xp: Int
    var gold: Int
    var level: Int
    var energy: Int          // 0–100
    var streakDays: Int
    var streakShieldActive: Bool
    var lastActiveDate: Date?
    var companionMoodRaw: String  // CompanionMood.rawValue

    init(
        xp: Int = 0,
        gold: Int = 0,
        level: Int = 1,
        energy: Int = 100,
        streakDays: Int = 0,
        streakShieldActive: Bool = false,
        lastActiveDate: Date? = nil,
        companionMood: CompanionMood = .neutral
    ) {
        self.xp = xp
        self.gold = gold
        self.level = level
        self.energy = energy
        self.streakDays = streakDays
        self.streakShieldActive = streakShieldActive
        self.lastActiveDate = lastActiveDate
        self.companionMoodRaw = companionMood.rawValue
    }

    var companionMood: CompanionMood {
        get { CompanionMood(rawValue: companionMoodRaw) ?? .neutral }
        set { companionMoodRaw = newValue.rawValue }
    }

    var isDead: Bool { energy <= 0 }

    var levelProgress: Double {
        let thresholds = GameModels.levelThresholds
        guard level < thresholds.count else { return 1.0 }
        let currentThreshold = thresholds[level - 1]
        let nextThreshold = thresholds[level]
        let range = nextThreshold.xpRequired - currentThreshold.xpRequired
        guard range > 0 else { return 1.0 }
        let progress = xp - currentThreshold.xpRequired
        return Double(progress) / Double(range)
    }

    var currentLevelTitle: String {
        let thresholds = GameModels.levelThresholds
        let idx = min(level - 1, thresholds.count - 1)
        return thresholds[idx].title
    }
}
