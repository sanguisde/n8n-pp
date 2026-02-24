import Foundation

// MARK: - GameEngine

/// Concrete implementation of GameEngineProtocol.
/// All logic is local/on-device – no network calls.
final class GameEngine: GameEngineProtocol {

    static let shared = GameEngine()
    private init() {}

    // MARK: - XP

    func xpGained(category: ActivityCategory, minutes: Int, streakMultiplier: Double = 1.0) -> Int {
        let base: Int
        switch category {
        case .productive: base = minutes * 2
        case .neutral:    base = minutes / 2
        case .harmful:    return 0
        }
        return max(1, Int(Double(base) * streakMultiplier))
    }

    // MARK: - Gold

    func goldGained(category: ActivityCategory, minutes: Int) -> Int {
        switch category {
        case .productive: return minutes
        case .neutral:    return 0
        case .harmful:    return -(minutes * 2)
        }
    }

    // MARK: - Energy

    func energyDelta(category: ActivityCategory, minutes: Int) -> Int {
        switch category {
        case .productive: return +min(minutes / 2, 20)
        case .neutral:    return +2
        case .harmful:    return -(minutes * 3)
        }
    }

    // MARK: - Apply Entry

    @discardableResult
    func applyEntry(category: ActivityCategory, minutes: Int, to profile: PlayerProfile) -> Bool {
        let streakMultiplier = streakMultiplier(for: profile.streakDays)

        // XP
        let xp = xpGained(category: category, minutes: minutes, streakMultiplier: streakMultiplier)
        profile.xp += xp

        // Gold
        let gold = goldGained(category: category, minutes: minutes)
        profile.gold = max(0, profile.gold + gold)

        // Energy
        let delta = energyDelta(category: category, minutes: minutes)
        profile.energy = max(0, min(100, profile.energy + delta))

        // Distraction Debt (Loss Aversion):
        // harmful → adds 2× the interval as penalty debt
        // productive → pays off existing debt 1:1 (XP/gold still awarded normally)
        switch category {
        case .harmful:
            profile.debtMinutes += minutes * 2
        case .productive where profile.debtMinutes > 0:
            profile.debtMinutes = max(0, profile.debtMinutes - minutes)
        default:
            break
        }

        // Handle death
        if profile.energy <= 0 {
            handleDeath(profile: profile)
        }

        // Level-up check
        return checkLevelUp(profile: profile)
    }

    // MARK: - Level-Up

    @discardableResult
    func checkLevelUp(profile: PlayerProfile) -> Bool {
        let thresholds = GameModels.levelThresholds
        var levelsGained = 0

        while profile.level < thresholds.count {
            let nextThreshold = thresholds[profile.level]
            if profile.xp >= nextThreshold.xpRequired {
                profile.level += 1
                levelsGained += 1
                // Restore energy on level-up
                profile.energy = min(100, profile.energy + 20)
            } else {
                break
            }
        }

        return levelsGained > 0
    }

    // MARK: - Death

    private func handleDeath(profile: PlayerProfile) {
        if profile.streakShieldActive {
            // Shield absorbs the death
            profile.streakShieldActive = false
            profile.energy = 10  // Barely survive
        } else {
            // Reset streak
            profile.streakDays = 0
            profile.energy = 0
            profile.companionMood = .disappointed
        }
    }

    // MARK: - Streak

    /// Counts workdays (Mon–Fri) strictly between `from` (exclusive) and `to` (inclusive).
    private func workdaysBetween(_ from: Date, _ to: Date) -> Int {
        let calendar = Calendar.current
        var count = 0
        var current = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: from))!
        let toStart = calendar.startOfDay(for: to)
        while current <= toStart {
            let wd = calendar.component(.weekday, from: current)
            if wd >= 2 && wd <= 6 { count += 1 }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return count
    }

    @discardableResult
    func updateStreak(profile: PlayerProfile, today: Date = Date()) -> Bool {
        guard let lastActive = profile.lastActiveDate else {
            profile.streakDays = 1
            profile.lastActiveDate = today
            return false
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        let lastStart = calendar.startOfDay(for: lastActive)

        // Same calendar day – no change
        if todayStart == lastStart { return false }

        let workdays = workdaysBetween(lastStart, todayStart)

        if workdays == 0 {
            // Only weekend days passed (e.g. logging on Saturday after Friday) – no change
            return false
        } else if workdays == 1 {
            // Next consecutive workday – extend streak (Fri→Mon counts as 1)
            profile.streakDays += 1
            profile.lastActiveDate = today

            // Award streak shield at 7 days
            if profile.streakDays >= 7 && !profile.streakShieldActive {
                profile.streakShieldActive = true
            }

            return false
        } else {
            // Gap in workdays – streak broken
            let wasActive = profile.streakDays > 0
            profile.streakDays = 1
            profile.lastActiveDate = today
            return wasActive
        }
    }

    // MARK: - Streak Multiplier

    private func streakMultiplier(for streakDays: Int) -> Double {
        switch streakDays {
        case 0...2:  return 1.0
        case 3...6:  return 1.25
        case 7...13: return 1.5
        case 14...29: return 1.75
        default:     return 2.0
        }
    }

    // MARK: - Achievements

    func checkAchievements(profile: PlayerProfile, totalEntries: Int, entries: [TimeEntry]) -> [String] {
        var newlyUnlocked: [String] = []

        // first_log
        if totalEntries >= 1 {
            newlyUnlocked.append("first_log")
        }

        // streak_3
        if profile.streakDays >= 3 {
            newlyUnlocked.append("streak_3")
        }

        // streak_7 + shield
        if profile.streakDays >= 7 {
            newlyUnlocked.append("streak_7")
        }

        // hundred_logs
        if totalEntries >= 100 {
            newlyUnlocked.append("hundred_logs")
        }

        // perfect_day – check if today has zero harmful entries
        let todayEntries = entries.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }
        if !todayEntries.isEmpty && !todayEntries.contains(where: {
            ActivityCategory(rawValue: $0.categoryValue) == .harmful
        }) {
            newlyUnlocked.append("perfect_day")
        }

        // level_5
        if profile.level >= 5 {
            newlyUnlocked.append("level_5")
        }

        // no_harmful_week
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.timestamp >= sevenDaysAgo }
        if recentEntries.count >= 7 &&
           !recentEntries.contains(where: { ActivityCategory(rawValue: $0.categoryValue) == .harmful }) {
            newlyUnlocked.append("no_harmful_week")
        }

        return newlyUnlocked
    }
}

// MARK: - DopaminMenu

final class DopaminMenu: DopaminMenuProvider {

    static let shared = DopaminMenu()
    private init() {}

    func nudge(for trigger: String) -> AppetitzerNudge? {
        let lower = trigger.lowercased()
        return GameModels.appetitzerNudges.first {
            $0.trigger.lowercased().contains(lower) || lower.contains($0.trigger.lowercased())
        }
    }

    func randomNudge() -> AppetitzerNudge {
        GameModels.appetitzerNudges.randomElement() ?? GameModels.appetitzerNudges[0]
    }

    func sidePairing(for activity: String) -> SidePairing? {
        let lower = activity.lowercased()
        return GameModels.sidePairings.first {
            $0.mainActivity.lowercased().contains(lower)
        }
    }
}

// MARK: - AICompanion

final class AICompanion: AICompanionProtocol {

    static let shared = AICompanion()
    private init() {}

    func sessionStartMessage(identityMode: IdentityMode) -> String {
        switch identityMode {
        case .standard:
            return "Ich bin dabei! Lass uns fokussiert bleiben."
        case .faith:
            return "Gott begleitet dich in dieser Arbeit. Sei gesegnet."
        }
    }

    func pomodoroCompleteMessage(count: Int, identityMode: IdentityMode) -> String {
        switch identityMode {
        case .standard:
            return "Super! \(count). Pomodoro geschafft. Kurze Pause?"
        case .faith:
            return "Ein Segment des Weges zurückgelegt. Dank sei Gott!"
        }
    }

    func sessionEndMessage(xpGained: Int, identityMode: IdentityMode) -> String {
        switch identityMode {
        case .standard:
            return "Großartige Session! +\(xpGained) XP verdient."
        case .faith:
            return "Treue Arbeit ist Gottesdienst. Du hast gut gedient. +\(xpGained) XP"
        }
    }

    func compassionateMessage(type: CompassionateResponseType, identityMode: IdentityMode) -> String {
        switch identityMode {
        case .standard:
            return standardMessage(type: type)
        case .faith:
            return faithMessage(type: type)
        }
    }

    private func standardMessage(type: CompassionateResponseType) -> String {
        switch type {
        case .afterFailureStreak:
            return [
                "Niemand ist jeden Tag perfekt. Was brauchst du jetzt?",
                "Manchmal ist Neutral das Beste, was wir können. Das ist okay.",
                "Drei schlechte Stunden definieren nicht deinen Tag."
            ].randomElement()!
        case .afterDeath:
            return "Dein Charakter ruht. Starte neu mit Würde."
        case .afterLongAbsence:
            return "Schön, dass du zurück bist. Fang klein an."
        case .afterMissedGoal:
            return "Das Ziel war vielleicht zu hoch. Lass uns es anpassen."
        case .celebrateSmallWin:
            return "Das war nur 30 Minuten – aber es zählt!"
        }
    }

    private func faithMessage(type: CompassionateResponseType) -> String {
        switch type {
        case .afterFailureStreak:
            return [
                "Gnade bedeutet: Immer wieder aufstehen. Du bist geliebt.",
                "Auch Petrus fiel – und stand wieder auf. Du auch.",
                "Gottes Barmherzigkeit ist jeden Morgen neu. (Klgl 3,23)"
            ].randomElement()!
        case .afterDeath:
            return "Auch im Fallen bist du gehalten. Starte neu in Seinem Licht."
        case .afterLongAbsence:
            return "Wie der verlorene Sohn – willkommen zurück. (Lk 15,20)"
        case .afterMissedGoal:
            return "Nicht Perfektion, sondern Treue zählt vor Gott."
        case .celebrateSmallWin:
            return "Wer im Kleinen treu ist, dem wird Großes anvertraut. (Mt 25,23)"
        }
    }

    func updateMood(profile: PlayerProfile, recentEntries: [TimeEntry]) {
        let last5 = recentEntries.suffix(5)
        let harmfulCount = last5.filter {
            ActivityCategory(rawValue: $0.categoryValue) == .harmful
        }.count
        let productiveCount = last5.filter {
            ActivityCategory(rawValue: $0.categoryValue) == .productive
        }.count

        if harmfulCount >= 3 {
            profile.companionMood = .worried
        } else if productiveCount >= 4 {
            profile.companionMood = profile.streakDays >= 7 ? .proud : .happy
        } else if profile.energy < 20 {
            profile.companionMood = .disappointed
        } else {
            profile.companionMood = .neutral
        }
    }
}
