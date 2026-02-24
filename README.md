# TimeAudit – macOS Menubar Time Tracking App

Ein persönliches Produktivitäts-Tracking-Tool für macOS als Menu-Bar-App. Alle 15 Minuten (konfigurierbar) erscheint ein Popup, in dem du deine aktuelle Tätigkeit kategorisierst und beschreibst – mit RPG-Gamification, Gartenvisualisierung und psychologischen Interventionen.

---

## Kernkonzept

Das Prinzip ist radikal einfach: **Was gemessen wird, verändert sich.** Jede Kategorie bekommt ein Gewicht (+1 / 0 / -1), und aus allen Einträgen eines Tages errechnet sich ein **Focus Score** (0–100). Zusätzlich gibt es ein RPG-System mit XP, Gold, Leveln und Achievements, das produktives Verhalten langfristig belohnt.

---

## Features im Detail

### Logging

- **Intervall-Timer**: Konfigurierbar auf 15, 30 oder 60 Minuten; Countdown im Menu Bar Popover und Desktop Widget sichtbar
- **Pflicht-Notiz**: Jeder Eintrag erfordert eine Freitext-Beschreibung – erzwingt Reflexion
- **3 Kategorien** mit festen Produktivitätsgewichten:

| Kategorie | Gewicht | Symbol |
|-----------|---------|--------|
| Produktiv (Umsatzgenerierend) | +1.0 | `chart.line.uptrend` |
| Neutral | 0.0 | `minus.circle` |
| Umsatzschädigend | -1.0 | `exclamationmark.triangle` |

- **Tastenkürzel**: 1, 2, 3 für direkte Kategorie-Auswahl im Popup
- **Smart Defaults**: Wenn die letzten 3 Einträge dieselbe Kategorie hatten, wird diese vorgeschlagen
- **Bestätigungs-Overlay**: Kurze visuelle Rückmeldung nach dem Speichern (0,7 Sek)

### Focus Score

- Berechnung: `(gewichteter Durchschnitt der Kategorien * 50) + 50`
- Wertebereich: 0–100
- Wird täglich neu berechnet und im Popover, im Widget und in der Statistik angezeigt
- Farbkodierung: Rot (<25), Orange (25–49), Blau (50–74), Grün (75+)

### RPG-Gamification

#### XP & Level
- **Produktiv**: `Minuten × 2 × Streak-Multiplikator` XP
- **Neutral**: `Minuten ÷ 2 × Streak-Multiplikator` XP
- **Schädigend**: 0 XP

| Level | XP-Schwelle | Standard-Titel | Faith-Titel |
|-------|------------|----------------|-------------|
| 1 | 0 | Anfänger | Suchender |
| 2 | 500 | Lehrling | Schüler |
| 3 | 1.500 | Geselle | Jünger |
| 4 | 3.500 | Handwerker | Treuer |
| 5 | 7.000 | Experte | Diener |
| 6 | 13.000 | Meister | Bote |
| 7 | 22.000 | Großmeister | Prophet |
| 8 | 35.000 | Champion | Gesalbter |
| 9 | 55.000 | Legende | Gesegneter |

#### Gold
- **Produktiv**: `+Minuten` Gold
- **Neutral**: 0
- **Schädigend**: `-(Minuten × 2)` Gold (kann negativ werden)

#### Energy (0–100)
- **Produktiv**: `+min(Minuten ÷ 2, 20)`
- **Neutral**: `+2`
- **Schädigend**: `-(Minuten × 3)`
- Bei 0 Energy: Streak-Reset oder Streak-Shield (einmalige Schutzwirkung ab 7 Tagen)

#### Streak & Multiplikatoren
- Produktiver Streak: Aufeinanderfolgende Tage mit ≥240 min produktiv
- Streak-Multiplikatoren: 1× (0–2 Tage), 1,25× (3–6), 1,5× (7–13), 1,75× (14–29), 2× (30+)
- Streak-Shield: Ab 7 Tagen aktiv – schützt einmalig vor Streak-Reset durch Energy-Tod

#### Achievements (8 Stück)

| ID | Name | Bedingung | XP | Gold |
|----|------|-----------|-----|------|
| first_log | Erster Schritt | 1 Eintrag | 50 | 10 |
| streak_3 | Beständig | 3-Tage-Streak | 200 | 50 |
| streak_7 | Wochenkrieger | 7-Tage-Streak | 500 | 150 |
| hundred_logs | Detektiv | 100 Einträge gesamt | 1.000 | 300 |
| perfect_day | Reiner Tag | Kein schädigender Eintrag heute | 300 | 100 |
| level_5 | Aufgestiegen | Level 5 erreicht | 500 | 200 |
| garden_bloom | Garten blüht | Focus Score > 80 | 200 | 75 |
| no_harmful_week | Reine Woche | 7 Tage ohne schädigende Einträge | 750 | 250 |

### Gartenvisualisierung (GardenView)

Canvas-gezeichneter Garten, der den Focus Score widerspiegelt:

- **Score < 40**: Kahler Baum, Dornen, Unkraut, dunkler Himmel
- **Score 40–60**: Vergilbter Baum, traurige Erde
- **Score 60–80**: Grüner Baum, Blumen, heller Himmel
- **Score 80+**: Voller Blüte, Schmetterlinge, Sterne
- **Faith-Modus zusätzlich**: Goldene Partikel, spirituelle Symbolik

Verfügbare Größen: `small` (20px), `medium` (80px), `large` (200px)

### Identitätsmodi (IdentityMode)

Globaler Schalter, der alle UI-Texte, Kategorienamen, Motivationsnachrichten und Leveltitel anpasst:

- **Standard**: Produktivitäts-fokussiert (Steve Jobs-Zitate, Produktivitätsthemen)
- **Faith**: Glaubens- und Berufungs-fokussiert (Bibelverse, Stewardship-Sprache)

Tägliche Impulse rotieren basierend auf dem Datum durch 20 Produktivitätszitate oder 20 Bibelverse.

### Loop-Breaker (InterventionViewModel)

Psychologisches Interventionssystem bei schädigenden Mustern:

- Zählt aufeinanderfolgende schädigende Einträge
- Bei **2+ schädigenden Einträgen** in Folge: Intervention-Popup erscheint statt des normalen Logging-Popups
- Inhalte:
  1. **Prompt**: Aufforderung zur Atem-/Gebetsübung
  2. **Timer**: 60-Sekunden-Countdown mit Kreisanimation
  3. **Abschluss**: Positives Feedback, dann normales Logging
- Mode-abhängige Texte ("Fokus-Verlust" vs. "Gaben-Verschwendung")

### Dopamin-Nudge (DopaminMenu)

Erscheint im Logging-Popup wenn Kategorie "Schädigend" gewählt wird:

- 8 kontextuelle Alternativen (z. B. Social Media → 5 min Natur beobachten, YouTube → 15 min spazieren)
- 5 Aktivitäts-Paarungen (z. B. E-Mails + Kaffee)
- Auto-Dismiss nach 8 Sekunden, manuell schließbar

### Companion (AICompanion)

Emotionaler Begleiter, dessen Stimmung sich dem Verhalten anpasst:

| Stimmung | Bedingung |
|----------|-----------|
| worried | 3+ schädigende in letzten 5 Einträgen |
| happy/proud | 4+ produktive in letzten 5 + guter Streak |
| disappointed | Energy < 20 |
| neutral | Sonst |

Generiert mode-abhängige Nachrichten für Session-Start, Intervall-Abschluss, Misserfolge, Erfolge.

### Statistiken

Vier Tabs im Statistik-Fenster (560×650 px):

#### Heute
- Tages-Breakdown: Kategorien mit Balkendiagramm, Minuten und Prozent
- Focus Score + Garden
- MissionBar (Produktivziel-Fortschritt)
- Tages-Impuls (Zitat/Bibelvers)
- Best/Worst Hour

#### Woche
- Gestapeltes Balkendiagramm der letzten 7 Tage (Swift Charts)
- Produktiv-Streak-Badge
- Kein-schädlicher-Streak-Badge
- Wochendurchschnitts-Score

#### Heatmap
- GitHub-Stil: Wochentag × Uhrzeit (4 Wochen)
- Farbintensität nach Aktivitätsvolumen
- Zeigt produktivste Tageszeiten

#### Profil
- Level-Badge + Titel
- XP-Fortschrittsbalken zum nächsten Level
- Energy-Balken (farbkodiert)
- Gold-Anzeige
- Streak + Streak-Shield-Status
- Companion-Stimmungs-Emoji
- 2-spaltiges Achievement-Grid (gesperrt: 🔒, entsperrt: 🏆 + Datum)

### Achievement Toast

Erscheint als Overlay über dem Menu Bar Popover bei:
- Achievement-Freischaltung: 🏆 Name + XP/Gold-Reward
- Level-Up: ⬆️ neuer Titel + Level-Badge

### MissionBar

Fortschrittsbalken für das tägliche Produktivitätsziel:

- **Manuell**: Ziel in Stunden einstellbar (1–8h)
- **Adaptiv**: Automatisch berechnet als 7-Tage-Durchschnitt + 10%
- Anzeige in Minuten oder "Einheiten" (alle 15 min = 1 Einheit)
- Mode-abhängige Labels

### Desktop Widget (FloatingWidget)

Immer-oben-schwebendes Fenster (260px breit):

- **Sichtbar auf allen Spaces** (auch in Fullscreen)
- Zeigt: Timer-Countdown, Focus Score, Notizfeld, 3 Kategorie-Buttons
- Licht-Design mit starkem Schatten für Sichtbarkeit auf jedem Desktop
- Position wird gespeichert und bei App-Start wiederhergestellt
- Kann verschoben werden (Drag)
- Kann Key-Window werden (Textfeld-Eingabe möglich) ohne Fokus zu stehlen

### Systembewusstsein

- **Sleep/Wake**: Popup erscheint sofort nach System-Wake
- **App Nap Prevention**: Timer läuft auch im Hintergrund weiter
- **Idle Detection** (IOKit): Erkennt inaktive Mac-Phasen ≥5 Minuten
- **Re-Reminder**: Wenn Popup >5 Minuten ignoriert wird, erneuter Sound
- **Globaler Hotkey**: `Cmd+Shift+T` öffnet Logging-Popup aus jeder App

---

## UI-Design-Prinzipien

- **Menu Bar Popover**: Helles Design (Off-White Hintergrund, dunkler Text, blauer Akzent)
- **Desktop Widget**: Helles Design mit farbigem Top-Balken, starker Schatten
- **Statistik/Settings**: Dunkles Design (`.preferredColorScheme(.dark)`)
- **Logging Popup**: Dunkel mit blauen Akzentfarben
- Durchgehend deutsche Sprache (UI, Fehlermeldungen, Motivationstexte)

---

## Datenstruktur

```
TimeEntry
├── timestamp: Date
├── categoryValue: Int (1=Produktiv, 2=Neutral, 3=Schädigend)
├── note: String (Pflicht)
└── intervalMinutes: Int

AppSettings
├── intervalMinutes: Int
├── soundEnabled: Bool
├── widgetEnabled: Bool
├── identityModeRaw: String
├── dailyGoalMinutes: Int
└── useAdaptiveGoal: Bool

PlayerProfile
├── xp: Int
├── gold: Int
├── level: Int
├── energy: Int (0–100)
├── streakDays: Int
├── streakShieldActive: Bool
├── lastActiveDate: Date?
└── companionMoodRaw: String

Achievement
├── achievementId: String (unique)
├── name: String
├── achievementDescription: String
├── isUnlocked: Bool
├── unlockedAt: Date?
├── xpReward: Int
└── goldReward: Int
```

**Speicherort**: `~/Library/Application Support/TimeAudit/default.store` (SQLite via SwiftData)
**Backup/Restore**: Über Einstellungen → Daten

---

## Projektstruktur

```
TimeAudit/
├── TimeAuditApp.swift              # @main, MenuBarExtra-Scene
├── AppDelegate.swift               # Lifecycle, Panels, Hotkeys, Monitoring
│
├── Models/
│   ├── TimeEntry.swift             # Haupt-Datensatz
│   ├── Category.swift              # ActivityCategory enum (3 Kategorien)
│   ├── AppSettings.swift           # Einstellungen (SwiftData)
│   ├── PlayerProfile.swift         # RPG-Spielerprofil (SwiftData)
│   ├── Achievement.swift           # Achievements (SwiftData)
│   ├── IdentityMode.swift          # Standard/Faith enum
│   └── GameModels.swift            # Level-Schwellen, Nudges, Quotes, Moods
│
├── ViewModels/
│   ├── TimerViewModel.swift        # Intervall-Timer, Wake-Handling
│   ├── LoggingViewModel.swift      # Kategorie-Auswahl, Smart Defaults
│   ├── StatisticsViewModel.swift   # Aggregation, Score, Streaks, Heatmap
│   ├── SettingsViewModel.swift     # Einstellungs-Persistenz
│   ├── InterventionViewModel.swift # Loop-Breaker-Logik
│   └── GameViewModel.swift         # RPG-State, Achievement-Checks, Toasts
│
├── Views/
│   ├── MenuBarView.swift           # Haupt-Popover (helles Design)
│   ├── LoggingPopupView.swift      # Logging-Popup (dunkles Design)
│   ├── FloatingWidgetView.swift    # Desktop Widget (helles Design)
│   ├── SettingsView.swift          # Einstellungen
│   ├── InterventionView.swift      # Loop-Breaker-Popup
│   ├── AchievementToastView.swift  # Achievement/Level-Up Toast
│   ├── ProfileView.swift           # RPG-Profil-Tab
│   └── Statistics/
│       ├── StatisticsView.swift    # Tab-Container
│       ├── DailyOverviewView.swift # Heute-Tab
│       ├── WeeklyChartView.swift   # Woche-Tab
│       └── HeatmapView.swift       # Heatmap-Tab
│
├── Components/
│   ├── FloatingPanel.swift         # NSPanel-Subklasse für Logging-Popup
│   ├── FloatingWidget.swift        # NSPanel-Subklasse für Desktop Widget
│   ├── GardenView.swift            # Canvas-Garten-Visualisierung
│   ├── MissionBar.swift            # Tagesziel-Fortschrittsbalken
│   ├── FocusScoreView.swift        # Kreisförmiger Score-Indikator
│   ├── StreakBadge.swift           # Streak-Anzeige (Flamme + Tage)
│   ├── DailyImpulseView.swift      # Zitat/Bibelvers-Karte
│   ├── DayBlocksView.swift         # Timeline-Blöcke (15-min-Raster)
│   └── CategoryButton.swift        # Kategorie-Auswahl-Button
│
├── Services/
│   ├── GameEngine.swift            # XP/Gold/Energy/Level-Berechnung
│   ├── DopaminMenu.swift           # Nudge-Vorschläge für schädigende Einträge
│   ├── AICompanion.swift           # Stimmungs- und Begleiter-Nachrichten
│   ├── IdentityProvider.swift      # Mode-abhängige Strings, Daily Impulses
│   ├── IdleDetector.swift          # IOKit Idle-Time-Überwachung
│   ├── SleepWakeMonitor.swift      # Sleep/Wake-Events
│   ├── CSVExporter.swift           # CSV-Export
│   └── SoundPlayer.swift           # Benachrichtigungstöne
│
└── Protocols/
    └── GameEngineProtocols.swift   # Interfaces für GameEngine, DopaminMenu, AICompanion
```

---

## Datenfluss

```
Eintrag gespeichert (TimeEntry)
  ↓
AppDelegate.onLogSaved()
  ├→ TimerViewModel.didLog()              → Timer zurücksetzen
  ├→ InterventionViewModel.recordCategory() → Schädigungs-Muster prüfen
  ├→ GameViewModel.processEntry()
  │   ├→ GameEngine.updateStreak()
  │   ├→ GameEngine.applyEntry()          → XP, Gold, Energy, Level-Up
  │   ├→ GameEngine.checkAchievements()   → Achievements freischalten
  │   └→ AICompanion.updateMood()         → Begleiter-Stimmung aktualisieren
  └→ StatisticsViewModel.refresh()
       ├→ computeToday()                  → Kategorien-Minuten, Focus Score
       ├→ computeWeekly()                 → 7-Tage-Daten
       ├→ computeStreaks()                 → Produktiv- und No-Harmful-Streak
       ├→ computeBestWorstHour()          → Beste/schlechteste Stunde
       ├→ computeHeatmap()                → 4-Wochen-Grid
       └→ computeMissionBar()             → Tagesziel-Fortschritt
```

---

## Tech Stack

- **SwiftUI** + **MenuBarExtra** (macOS 14+)
- **SwiftData** – lokale Persistenz (SQLite)
- **Swift Charts** – Wochen-Balkendiagramm
- **IOKit** – Idle-Time-Erkennung
- **SMAppService** – Launch at Login (macOS 13+)
- **NSPanel** – Floating Panels für Popups und Widget
- **NSVisualEffectView** – Blur-Hintergrund für Widget
- **Canvas / GraphicsContext** – Garten-Visualisierung
- **MVVM** – Architekturmuster

---

## Setup in Xcode

1. Xcode 16.0+ öffnen
2. **File > Open** → `TimeAudit.xcodeproj`
3. Target auswählen → **Signing & Capabilities**: Team eintragen
4. **Build and Run** (`Cmd+R`)

**Voraussetzungen**:
- macOS 14.0+ als Deployment Target
- Kein App Store – lokale Entwicklung/persönliche Nutzung
- `LSUIElement = true` in Info.plist (App erscheint nicht im Dock)

---

## Einstellungen

| Einstellung | Optionen | Standard |
|-------------|----------|----------|
| Intervall | 15 / 30 / 60 min | 15 min |
| Benachrichtigungston | An/Aus | An |
| Identitätsmodus | Standard / Faith | Standard |
| Tagesziel | 1–8 Stunden | 4 Stunden |
| Adaptives Ziel | An/Aus | Aus |
| Desktop Widget | An/Aus | Aus |
| Beim Login starten | An/Aus | Aus |

---

## Datenschutz

Alle Daten bleiben **lokal** auf dem Gerät. Keine Cloud, keine externen APIs, kein Tracking.

---

## Lizenz

Persönliche Nutzung.
