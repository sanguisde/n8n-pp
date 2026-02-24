import Foundation

// MARK: - CompanionMood

enum CompanionMood: String, CaseIterable, Codable {
    case happy = "happy"
    case neutral = "neutral"
    case worried = "worried"
    case disappointed = "disappointed"
    case proud = "proud"
    case energized = "energized"

    var emoji: String {
        switch self {
        case .happy:       return "😊"
        case .neutral:     return "😐"
        case .worried:     return "😟"
        case .disappointed: return "😞"
        case .proud:       return "😄"
        case .energized:   return "⚡️"
        }
    }
}

// MARK: - Emotion

enum Emotion: String, CaseIterable, Codable {
    case focused = "focused"
    case tired = "tired"
    case anxious = "anxious"
    case motivated = "motivated"
    case bored = "bored"
    case stressed = "stressed"
    case calm = "calm"
    case energized = "energized"

    var displayName: String {
        switch self {
        case .focused:   return "Fokussiert"
        case .tired:     return "Müde"
        case .anxious:   return "Ängstlich"
        case .motivated: return "Motiviert"
        case .bored:     return "Gelangweilt"
        case .stressed:  return "Gestresst"
        case .calm:      return "Ruhig"
        case .energized: return "Energiegeladen"
        }
    }

    var emoji: String {
        switch self {
        case .focused:   return "🎯"
        case .tired:     return "😴"
        case .anxious:   return "😰"
        case .motivated: return "💪"
        case .bored:     return "😑"
        case .stressed:  return "😤"
        case .calm:      return "🧘"
        case .energized: return "⚡️"
        }
    }
}

// MARK: - AppetitzerNudge

struct AppetitzerNudge {
    let trigger: String
    let alternative: String
    let durationMinutes: Int
    let benefit: String
}

// MARK: - SidePairing

struct SidePairing {
    let mainActivity: String
    let pairing: String
    let benefit: String
}

// MARK: - LevelThreshold

struct LevelThreshold {
    let level: Int
    let xpRequired: Int
    let title: String
    let faithTitle: String
}

// MARK: - AchievementDefinition

struct AchievementDefinition {
    let id: String
    let name: String
    let description: String
    let xpReward: Int
    let goldReward: Int
}

// MARK: - GameModels Predefined Data

enum GameModels {

    static let levelThresholds: [LevelThreshold] = [
        LevelThreshold(level: 1, xpRequired: 0,     title: "Anfänger",    faithTitle: "Suchender"),
        LevelThreshold(level: 2, xpRequired: 500,   title: "Lehrling",    faithTitle: "Schüler"),
        LevelThreshold(level: 3, xpRequired: 1500,  title: "Geselle",     faithTitle: "Jünger"),
        LevelThreshold(level: 4, xpRequired: 3500,  title: "Handwerker",  faithTitle: "Treuer"),
        LevelThreshold(level: 5, xpRequired: 7000,  title: "Experte",     faithTitle: "Diener"),
        LevelThreshold(level: 6, xpRequired: 13000, title: "Meister",     faithTitle: "Bote"),
        LevelThreshold(level: 7, xpRequired: 22000, title: "Großmeister", faithTitle: "Prophet"),
        LevelThreshold(level: 8, xpRequired: 35000, title: "Champion",    faithTitle: "Gesalbter"),
        LevelThreshold(level: 9, xpRequired: 55000, title: "Legende",     faithTitle: "Gesegneter"),
    ]

    static let appetitzerNudges: [AppetitzerNudge] = [
        AppetitzerNudge(
            trigger: "Social Media",
            alternative: "5 Minuten Fenster öffnen & Natur anschauen",
            durationMinutes: 5,
            benefit: "Ruhige Stille statt Dopamin-Überflutung"
        ),
        AppetitzerNudge(
            trigger: "Nachrichten lesen",
            alternative: "Kurzen Journal-Eintrag schreiben",
            durationMinutes: 10,
            benefit: "Eigene Gedanken statt fremder Meinungen"
        ),
        AppetitzerNudge(
            trigger: "YouTube / TV",
            alternative: "15-minütiger Spaziergang",
            durationMinutes: 15,
            benefit: "Bewegung reaktiviert den Fokus"
        ),
        AppetitzerNudge(
            trigger: "Online Shopping",
            alternative: "Wunschliste offline notieren",
            durationMinutes: 5,
            benefit: "Impulskäufe vermeiden, Wünsche bewusster machen"
        ),
        AppetitzerNudge(
            trigger: "Gaming",
            alternative: "20 Minuten Sport oder Körperübung",
            durationMinutes: 20,
            benefit: "Natürliches Dopamin durch Bewegung"
        ),
        AppetitzerNudge(
            trigger: "Endloses Scrollen",
            alternative: "3 Minuten Atemübung (4-7-8)",
            durationMinutes: 3,
            benefit: "Nervensystem beruhigen, Klarheit gewinnen"
        ),
        AppetitzerNudge(
            trigger: "Ablenkende Gespräche",
            alternative: "Task-Liste für die nächste Stunde schreiben",
            durationMinutes: 5,
            benefit: "Fokus zurück auf eigene Prioritäten"
        ),
        AppetitzerNudge(
            trigger: "Prokrastination",
            alternative: "2-Minuten-Regel: Sofort die kleinste Teilaufgabe tun",
            durationMinutes: 2,
            benefit: "Bewegung bricht den Widerstand"
        ),
    ]

    static let sidePairings: [SidePairing] = [
        SidePairing(
            mainActivity: "E-Mails beantworten",
            pairing: "Kaffee oder Tee trinken",
            benefit: "Ritualisierung schafft Fokus-Anker"
        ),
        SidePairing(
            mainActivity: "Tiefe Arbeit / Konzentration",
            pairing: "Instrumentalmusik oder White Noise",
            benefit: "Ablenkung reduzieren ohne Isolation"
        ),
        SidePairing(
            mainActivity: "Telefonkonferenzen",
            pairing: "Spazieren gehen (wenn möglich)",
            benefit: "Bewegung steigert Konzentration & Energie"
        ),
        SidePairing(
            mainActivity: "Administrative Aufgaben",
            pairing: "Podcast oder Hörbuch",
            benefit: "Monotone Aufgaben angenehmer gestalten"
        ),
        SidePairing(
            mainActivity: "Kreative Arbeit",
            pairing: "Natürliches Licht & Pflanze in Sichtweite",
            benefit: "Biophilie steigert Kreativität"
        ),
    ]

    static let achievementDefinitions: [AchievementDefinition] = [
        AchievementDefinition(id: "first_log",       name: "Erster Schritt",   description: "Ersten Zeiteintrag erfasst",                      xpReward: 50,   goldReward: 10),
        AchievementDefinition(id: "streak_3",        name: "Drei Tage stark",  description: "3 Tage Streak aufgebaut",                         xpReward: 200,  goldReward: 50),
        AchievementDefinition(id: "streak_7",        name: "Eine Woche Treue", description: "7 Tage Streak aufgebaut",                         xpReward: 500,  goldReward: 150),
        AchievementDefinition(id: "hundred_logs",    name: "Hundert Momente",  description: "100 Zeiteinträge erfasst",                        xpReward: 1000, goldReward: 300),
        AchievementDefinition(id: "perfect_day",     name: "Perfekter Tag",    description: "Kein schädlicher Eintrag an einem ganzen Tag",    xpReward: 300,  goldReward: 100),
        AchievementDefinition(id: "level_5",         name: "Experte",          description: "Level 5 erreicht",                               xpReward: 500,  goldReward: 200),
        AchievementDefinition(id: "garden_bloom",    name: "Blüte",            description: "Garden-Score über 80 erreicht",                   xpReward: 200,  goldReward: 75),
        AchievementDefinition(id: "no_harmful_week", name: "Reine Woche",      description: "7 Tage ohne schädlichen Eintrag",                 xpReward: 750,  goldReward: 250),
    ]
}
