import Foundation

// MARK: - GameEngineProtocol

/// Core protocol for XP, Gold, Level, Energy, and Achievement logic.
protocol GameEngineProtocol {

    /// Calculates XP gained for a logged entry.
    func xpGained(category: ActivityCategory, minutes: Int, streakMultiplier: Double) -> Int

    /// Calculates Gold gained (or lost) for a logged entry.
    func goldGained(category: ActivityCategory, minutes: Int) -> Int

    /// Calculates Energy delta for a logged entry.
    func energyDelta(category: ActivityCategory, minutes: Int) -> Int

    /// Applies a logged entry to the player profile and checks for level-ups.
    /// Returns true if a level-up occurred.
    @discardableResult
    func applyEntry(category: ActivityCategory, minutes: Int, to profile: PlayerProfile) -> Bool

    /// Checks which achievements should be unlocked given current profile + entries.
    /// Returns newly unlocked achievement IDs.
    func checkAchievements(profile: PlayerProfile, totalEntries: Int, entries: [TimeEntry]) -> [String]

    /// Updates streak based on lastActiveDate. Returns true if streak was broken.
    @discardableResult
    func updateStreak(profile: PlayerProfile, today: Date) -> Bool
}

// MARK: - DopaminMenuProvider

/// Provides contextual nudges and side-pairings to the user.
protocol DopaminMenuProvider {

    /// Returns a nudge suggestion for the given trigger string (partial match).
    func nudge(for trigger: String) -> AppetitzerNudge?

    /// Returns a random nudge suitable as a general suggestion.
    func randomNudge() -> AppetitzerNudge

    /// Returns a side-pairing suggestion for the given activity.
    func sidePairing(for activity: String) -> SidePairing?
}

// MARK: - AICompanionProtocol

/// Provides companion messages and compassionate responses.
protocol AICompanionProtocol {

    /// Message shown when a body-double session starts.
    func sessionStartMessage(identityMode: IdentityMode) -> String

    /// Message shown at each Pomodoro interval.
    func pomodoroCompleteMessage(count: Int, identityMode: IdentityMode) -> String

    /// Message shown when a session ends.
    func sessionEndMessage(xpGained: Int, identityMode: IdentityMode) -> String

    /// Compassionate message after consecutive harmful entries.
    func compassionateMessage(type: CompassionateResponseType, identityMode: IdentityMode) -> String

    /// Updates the companion mood based on recent entry patterns.
    func updateMood(profile: PlayerProfile, recentEntries: [TimeEntry])
}

// MARK: - CompassionateResponseType

enum CompassionateResponseType {
    case afterFailureStreak
    case afterDeath
    case afterLongAbsence
    case afterMissedGoal
    case celebrateSmallWin
}
