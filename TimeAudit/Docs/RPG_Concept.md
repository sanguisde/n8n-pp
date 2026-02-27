# TimeAudit RPG / Gamification – Konzept & Brainstorm

> Status: Brainstorm / Architektur-Skizze – noch nicht implementiert
> Erstellt im Rahmen von Phase C (Feb 2026)

---

## Überblick

Dieses Dokument beschreibt das geplante Gamification-System für TimeAudit.
Ziel ist es, das Tracken von Zeit emotional bedeutsam zu machen – nicht durch äußere Belohnungen,
sondern durch eine tiefe Identitätsbindung: Wer bin ich? Welcher Charakter will ich werden?

---

## Feature 1: XP & Gold-System

### Konzept
- Jede Zeiterfassung vergibt XP und Gold
- Produktive Einträge: +XP, +Gold
- Neutrale Einträge: +kleines XP
- Schädliche Einträge: Kein XP, Gold-Abzug

### Formel (Entwurf)
```swift
func xpGained(category: ActivityCategory, minutes: Int, streakMultiplier: Double) -> Int {
    let base: Int
    switch category {
    case .productive: base = minutes * 2
    case .neutral:    base = minutes / 2
    case .harmful:    return 0
    }
    return Int(Double(base) * streakMultiplier)
}

func goldGained(category: ActivityCategory, minutes: Int) -> Int {
    switch category {
    case .productive: return minutes
    case .neutral:    return 0
    case .harmful:    return -(minutes * 2)  // Gold-Abzug
    }
}
```

### Level-Schwellen
| Level | XP benötigt | Titel (Standard) | Titel (Faith) |
|-------|-------------|------------------|---------------|
| 1     | 0           | Anfänger         | Suchender     |
| 2     | 500         | Lehrling         | Schüler       |
| 3     | 1500        | Geselle          | Jünger        |
| 4     | 3500        | Handwerker       | Treuer        |
| 5     | 7000        | Experte          | Diener        |
| 6     | 13000       | Meister          | Bote          |
| 7     | 22000       | Großmeister      | Prophet       |
| 8     | 35000       | Champion         | Gesalbter     |
| 9     | 55000       | Legende          | Gesegneter    |

---

## Feature 2: Death Mechanic (Energy-System)

### Konzept
- Charakter hat Energie 0–100
- Schädliche Einträge kosten Energie
- Neutrale Einträge: minimale Erholung
- Produktive Einträge: volle Erholung
- Bei Energie = 0: "Charakter stirbt" → Streak verloren, visuelles Reset

### Energie-Logik
```swift
func energyDelta(category: ActivityCategory, minutes: Int) -> Int {
    switch category {
    case .productive: return +min(minutes / 2, 20)
    case .neutral:    return +2
    case .harmful:    return -(minutes * 3)
    }
}
```

### Tod-Sequenz
1. Energie < 20: Rotes Pulsieren am Garden
2. Energie = 0: "Dein Charakter ist erschöpft" – Modal mit Konsequenz-Beschreibung
3. Streak auf 0, Streak-Shield verbraucht (falls aktiv)
4. Garden zeigt verwelkten Zustand für 24h

### Streak Shield
- Verdient durch 7+ Tage Streak
- Verhindert einmalig den Death-Reset
- Wird automatisch verbraucht

---

## Feature 3: Dopamin-Menü / Appetizer-System

### Konzept
Wenn der Benutzer schädliche oder neutrale Aktivitäten plant, schlägt die App eine
„gesunde Alternative" vor – ein mentales Gegenmittel zum Dopamin-Trigger.

### Nudge-Typen
```swift
struct AppetitzerNudge {
    let trigger: String      // z.B. "Social Media"
    let alternative: String  // z.B. "5 Minuten Gartenblick"
    let duration: Int        // Minuten
    let category: ActivityCategory
}
```

### Beispiel-Nudges
| Trigger | Alternative | Dauer |
|---------|-------------|-------|
| Social Media scrollen | 5 Minuten Natur-Video | 5 min |
| Zeitung/News lesen | Journal-Eintrag | 10 min |
| YouTube/TV | Kurzer Spaziergang | 15 min |
| Online Shopping | Wunschliste offline | 5 min |
| Gaming | Körperübung | 20 min |

### Side Pairings (Produktives + Neutrales kombinieren)
```swift
struct SidePairing {
    let mainActivity: String
    let pairing: String
    let benefit: String
}
```
Beispiel: "Emails bearbeiten + Kaffee trinken" → "Ritualisierung hilft beim Fokus"

---

## Feature 4: Apple Intelligence Integration

### Konzept
Nutzt Apple Intelligence / on-device LLM für personalisierte Reflexionen.

### Geplante Funktionen
1. **Tages-Reflexion**: Am Abend generiert AI eine persönliche Zusammenfassung
2. **Pattern-Erkennung**: "Du bist Dienstags am produktivsten"
3. **Intelligente Zielsetzung**: Schlägt realistischere Tagesziele vor
4. **Kontext-Impulse**: Basierend auf aktueller Zeit + Wochentag

### Technische Ansätze
```swift
// Option A: Foundation Models Framework (macOS 15+)
import FoundationModels

// Option B: Lokales Prompt-Engineering mit Regeln
struct AIReflectionEngine {
    func generateDailyReflection(entries: [TimeEntry], profile: PlayerProfile) -> String
    func detectPatterns(entries: [TimeEntry], days: Int) -> [PatternInsight]
    func suggestGoal(history: [TimeEntry], currentGoal: Int) -> Int
}
```

### Datenschutz-Strategie
- Alles on-device, keine Cloud-Übertragung
- Opt-in für Apple Intelligence
- Fallback auf regelbasierte Texte (wie DailyImpulse bereits)

---

## Feature 5: AI Body Doubling

### Konzept
Virtuelle Arbeitsbegleitung – der Charakter "arbeitet mit" während du arbeitest.

### Ablauf
1. Benutzer startet "Body Double Session"
2. Timer läuft sichtbar im Menu Bar
3. Companion gibt alle 25 Minuten (Pomodoro) eine Nachricht
4. Am Ende: Lob, XP-Bonus, Companion-Mood-Update

### Companion Moods
```swift
enum CompanionMood: String, Codable {
    case happy = "happy"
    case neutral = "neutral"
    case worried = "worried"
    case disappointed = "disappointed"
    case proud = "proud"
    case energized = "energized"
}
```

### Companion Nachrichten (Standard)
- Start: "Ich bin dabei! Lass uns fokussiert bleiben."
- 25 min: "Super! Eine Pomodoro geschafft. Kurze Pause?"
- Ende: "Großartige Session! +{xp} XP verdient."

### Companion Nachrichten (Faith-Modus)
- Start: "Gott begleitet dich in dieser Arbeit. Sei gesegnet."
- 25 min: "Ein Segment des Weges zurückgelegt. Dank sei Gott!"
- Ende: "Treue Arbeit ist Gottesdienst. Du hast gut gedient. +{xp} XP"

---

## Feature 6: Compassionate AI

### Konzept
Anstatt nur zu gamifizieren, soll die AI auch Mitgefühl zeigen.
Besonders nach schlechten Phasen – keine Beschämung, aber sanfte Neuorientierung.

### Trigger-Szenarien
1. Nach 3+ schädlichen Einträgen in Folge
2. Nach einem Energie-Tod
3. Nach einer langen Pause (3+ Tage ohne Tracking)
4. Nach Ziel-Verfehlung mehrere Tage

### Compassionate Response-Typen
```swift
enum CompassionateResponseType {
    case afterFailureStreak       // "Das passiert. Was brauchst du gerade?"
    case afterDeath               // "Dein Charakter ruht. Starte neu mit Würde."
    case afterLongAbsence         // "Schön, dass du zurück bist."
    case afterMissedGoal          // "Das Ziel war vielleicht zu hoch. Lass uns anpassen."
    case celebrateSmallWin        // "Das war nur 30 Min – aber es zählt!"
}
```

### Response-Texte (Standard-Modus)
```swift
let afterFailureStreak = [
    "Niemand ist jeden Tag perfekt. Was brauchst du jetzt?",
    "Manchmal ist Neutral das Beste, was wir können. Das ist okay.",
    "Drei schlechte Stunden definieren nicht deinen Tag."
]
```

### Response-Texte (Faith-Modus)
```swift
let afterFailureStreak = [
    "Gnade bedeutet: Immer wieder aufstehen. Du bist geliebt.",
    "Auch Petrus fiel – und stand wieder auf. Du auch.",
    "Gottes Barmherzigkeit ist jeden Morgen neu."
]
```

---

## Feature 7: Emotionale Zustandsverfolgung

### Konzept
Beim Eintragen kann der Benutzer optional eine Emotion angeben.

### Emotion-Typen
```swift
enum Emotion: String, CaseIterable, Codable {
    case focused = "focused"
    case tired = "tired"
    case anxious = "anxious"
    case motivated = "motivated"
    case bored = "bored"
    case stressed = "stressed"
    case calm = "calm"
    case energized = "energized"
}
```

### UI-Integration
- Optional nach der Kategorie-Auswahl
- Kleine Emoji-Reihe (5 häufigste Emotionen)
- Gespeichert in TimeEntry (optionales Feld)
- Statistik: "Du bist produktiver wenn du 'calm' bist"

---

## Feature 8: Achievements

### Konzept
Meilensteine die dauerhaft freigeschaltet werden.

### Beispiel-Achievements
| ID | Name | Bedingung | XP | Gold |
|----|------|-----------|-----|------|
| first_log | Erster Schritt | 1. Eintrag | 50 | 10 |
| streak_3 | Drei Tage stark | 3 Tage Streak | 200 | 50 |
| streak_7 | Eine Woche Treue | 7 Tage Streak | 500 | 150 |
| hundred_logs | Hundert Momente | 100 Einträge | 1000 | 300 |
| perfect_day | Perfekter Tag | 0 schädliche Einträge an einem Tag | 300 | 100 |
| level_5 | Experte | Level 5 erreicht | 500 | 200 |
| garden_bloom | Blüte | Garden-Score > 80 | 200 | 75 |
| no_harmful_week | Reine Woche | 7 Tage ohne schädlichen Eintrag | 750 | 250 |

---

## Feature 9: Visuelle Gamification-Elemente

### Charakter-Avatar
- Kleine Pixel-Art oder SF Symbol basierte Darstellung
- Ändert Aussehen basierend auf Level
- Faith-Modus: Andere Kleidung / Aureole

### Gold-Anzeige
- Sichtbar im Menu Bar Extra (klein)
- Animierter "+Gold" Aufstieg nach produktivem Eintrag
- Goldmünzen-Sound optional

### XP-Bar
- Unter dem Garden oder in der Statistics View
- Smooth-Animierung beim XP-Gewinn

---

## Architektur-Übersicht

```
GameEngine (Protocol + Service)
├── XP-Berechnung
├── Gold-Berechnung
├── Level-Up-Logik
├── Achievement-Checking
└── Energy-Management

PlayerProfile (SwiftData @Model)
├── xp: Int
├── gold: Int
├── level: Int
├── energy: Int (0-100)
├── streakDays: Int
├── streakShieldActive: Bool
└── companionMood: CompanionMood

Achievement (SwiftData @Model)
├── achievementId: String (unique)
├── name: String
├── isUnlocked: Bool
└── rewards: (xp, gold)

GameModels
├── LevelThreshold[]
├── AppetitzerNudge[]
├── SidePairing[]
└── Emotion[]
```

---

## Priorisierung (empfohlen)

| Prio | Feature | Aufwand | Impact |
|------|---------|---------|--------|
| 1 | XP & Gold (Grundlogik) | Mittel | Hoch |
| 2 | Achievements | Niedrig | Hoch |
| 3 | Energy / Death Mechanic | Mittel | Hoch |
| 4 | Dopamin-Menü | Niedrig | Mittel |
| 5 | Compassionate AI | Niedrig | Hoch |
| 6 | Body Doubling | Mittel | Mittel |
| 7 | Emotionen | Niedrig | Mittel |
| 8 | Apple Intelligence | Hoch | Hoch |
| 9 | Visuelle Elemente | Hoch | Mittel |

---

## Technische Voraussetzungen

- SwiftData Schema-Migration (neue @Model Klassen)
- Kein iCloud Sync in V1 (zu komplex)
- Alle berechnungen lokal, on-device
- SwiftUI Animationen für XP/Gold-Aufstieg
- Canvas API (bereits genutzt für Garden) für Charakter-Darstellung

---

*Dieses Dokument wird iterativ erweitert sobald einzelne Features implementiert werden.*
