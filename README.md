# TimeAudit – macOS Menubar Time Tracking App

Ein persönliches Produktivitäts-Tracking-Tool für macOS als Menu-Bar-App. Alle 15 Minuten (konfigurierbar) erscheint ein Popup, in dem du deine aktuelle Tätigkeit kategorisierst und beschreibst – mit RPG-Gamification, psychologischen Interventionen und Commitment-Mechanismen.

---

## Kernkonzept

**Was gemessen wird, verändert sich.** Jede Kategorie bekommt ein Gewicht (+1 / 0 / -1), und aus allen Einträgen eines Tages errechnet sich ein **Focus Score** (0–100). Zusätzlich gibt es ein RPG-System mit XP, Gold, Leveln und Achievements, das produktives Verhalten langfristig belohnt – und ein Distraction-Debt-System, das Ablenkungskosten direkt sichtbar macht.

---

## Features im Detail

### Logging

- **Intervall-Timer**: Konfigurierbar auf 15, 30 oder 60 Minuten; Countdown im Menu Bar Popover und Desktop Widget sichtbar
- **Pflicht-Notiz**: Jeder Eintrag erfordert eine Freitext-Beschreibung – erzwingt Reflexion
- **3 Kategorien** mit festen Produktivitätsgewichten:

| Kategorie | Gewicht | Symbol |
|-----------|---------|--------|
| Umsatzgenerierend | +1.0 | `chart.line.uptrend` |
| Neutral | 0.0 | `minus.circle` |
| Ablenkung | -1.0 | `exclamationmark.triangle` |

- **Tastenkürzel**: 1, 2, 3 für direkte Kategorie-Auswahl im Popup
- **Letzten Eintrag wiederholen**: Ein Tap füllt Note + Kategorie aus dem letzten Eintrag vor – kein erneutes Tippen bei langen Focus-Sessions
- **Smart Defaults**: Wenn die letzten 3 Einträge dieselbe Kategorie hatten, wird diese vorgeschlagen
- **Bestätigungs-Overlay**: Kurze visuelle Rückmeldung nach dem Speichern

### Morning Intention

Jeden Tag nach 8:00 Uhr beim ersten App-Start erscheint ein **Morgen-Popup**:

- **3 Prioritäten**: Was sind die 3 wichtigsten Aufgaben heute?
- **Vermeidungs-Commitment**: Was wirst du heute aktiv vermeiden? (z. B. Instagram, Slack-Rabbit-Holes)
- Einmalig pro Tag (wird per UserDefaults getrackt)
- Kann mit "Später" übersprungen werden

### Evening Debrief

Um **17:30 Uhr** erscheint automatisch ein Tages-Abschluss-Popup:

- **Prioritäten-Checkboxen**: Welche der 3 Prioritäten hast du erledigt? (mit Animation + Strikethrough)
- **Größter Erfolg**: Freies Textfeld für den besten Moment des Tages
- **Morgen wiederholen**: Was hat so gut funktioniert, dass es wiederholt werden sollte?
- Einmalig pro Tag (verhindert wiederholtes Erscheinen nach 17:30)

### Focus Score

- Berechnung: `(gewichteter Durchschnitt der Kategorien × 50) + 50`
- Wertebereich: 0–100
- Farbkodierung: Rot (<25), Orange (25–49), Blau (50–74), Grün (75+)
- Wird täglich neu berechnet und in Popover, Widget und Statistik angezeigt

### Wochenend-Logik

Samstag und Sonntag:
- Einträge werden **weiterhin gespeichert** (für persönliches Tracking)
- Fließen aber **nicht** in Focus Score, XP, Gold, Energy oder Streaks ein
- Fr → Mo gilt als konsekutiver Arbeitstag (Streak-Unterbrechung nur durch fehlende Werktage)
- MenuBar zeigt "🌴 Wochenende – kein Druck"

### RPG-Gamification

#### XP & Level
- **Umsatzgenerierend**: `Minuten × 2 × Streak-Multiplikator × Flow-Multiplikator` XP
- **Neutral**: `Minuten ÷ 2 × Streak-Multiplikator` XP
- **Ablenkung**: 0 XP

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
- **Umsatzgenerierend**: `+Minuten` Gold
- **Neutral**: 0
- **Ablenkung**: `-(Minuten × 2)` Gold (Minimum: 0)

#### Energy (0–100)
- **Umsatzgenerierend**: `+min(Minuten ÷ 2, 20)`
- **Neutral**: `+2`
- **Ablenkung**: `-(Minuten × 3)`
- Bei 0 Energy: Streak-Reset oder Streak-Shield (einmalige Schutzwirkung ab 7 Tagen)

#### Flow State ⚡
- Nach **3 oder mehr aufeinanderfolgenden** produktiven Einträgen: **1,5× XP-Multiplikator**
- Zurückgesetzt durch einen Ablenkung-Eintrag
- Neutral-Einträge unterbrechen den Flow **nicht**
- Im Desktop Widget: grünes **⚡ FLOW** Badge sichtbar

#### Streak & Multiplikatoren
- Streak-Multiplikatoren: 1× (0–2 Tage), 1,25× (3–6), 1,5× (7–13), 1,75× (14–29), 2× (30+)
- Streak-Shield: Ab 7 Tagen aktiv – schützt einmalig vor Streak-Reset durch Energy-Tod

#### Distraction Debt (Ablenkungsschulden)
- Jede Ablenkung erzeugt `Minuten × 2` Schulden-Minuten
- Produktive Arbeit zahlt Schulden 1:1 ab
- Rote Schulden-Banner erscheinen in Widget und MenuBar
- Schulden bleiben über Tage erhalten bis vollständig abgebaut

#### Achievements (8 Stück)

| ID | Name | Bedingung | XP | Gold |
|----|------|-----------|-----|------|
| first_log | Erster Schritt | 1 Eintrag | 50 | 10 |
| streak_3 | Beständig | 3-Tage-Streak | 200 | 50 |
| streak_7 | Wochenkrieger | 7-Tage-Streak | 500 | 150 |
| hundred_logs | Detektiv | 100 Einträge gesamt | 1.000 | 300 |
| perfect_day | Reiner Tag | Kein Ablenkung-Eintrag heute | 300 | 100 |
| level_5 | Aufgestiegen | Level 5 erreicht | 500 | 200 |
| garden_bloom | Garten blüht | Focus Score > 80 | 200 | 75 |
| no_harmful_week | Reine Woche | 7 Tage ohne Ablenkung-Einträge | 750 | 250 |

### Weekly League 🏆

Vergleich der aktuellen 7 Tage mit den vorherigen 7 Tagen im MenuBar Popover:
- **Focus Score** aktuell vs. vorher (mit ↑/↓ Delta)
- **Produktive Minuten** aktuell vs. vorher (mit ±Differenz)

### Micro-Intervention (Loop-Breaker)

Erscheint statt des normalen Logging-Popups wenn **2+ Ablenkung-Einträge in Folge** erkannt werden:

- **"Du bist im Ablenkungsmodus"** – klare Situationsdiagnose
- **Next-Task-Commitment**: Textfeld für die nächste konkrete Aufgabe
- **[Jetzt loggen]**: Direkt ins normale Logging-Popup weiter
- **[Durchatmen]**: 60-Sekunden Atem-Timer mit Kreisanimation; danach automatischer Übergang zum Logging
- Mode-abhängige Texte (Standard vs. Faith)

### Gartenvisualisierung (GardenView)

Canvas-gezeichneter Garten, der den Focus Score widerspiegelt:

- **Score < 40**: Kahler Baum, Dornen, Unkraut, dunkler Himmel
- **Score 40–60**: Vergilbter Baum, traurige Erde
- **Score 60–80**: Grüner Baum, Blumen, heller Himmel
- **Score 80+**: Voller Blüte, Schmetterlinge, Sterne
- **Faith-Modus zusätzlich**: Goldene Partikel, spirituelle Symbolik

### Identitätsmodi (IdentityMode)

Globaler Schalter, der alle UI-Texte, Kategorienamen, Motivationsnachrichten und Leveltitel anpasst:

- **Standard**: Produktivitäts-fokussiert (Produktivitätszitate, unternehmerische Sprache)
- **Faith**: Glaubens- und Berufungs-fokussiert (Bibelverse, Stewardship-Sprache)

Tägliche Impulse rotieren basierend auf dem Datum durch 20 Einträge.

### AI Body Double (Companion)

Pixel-Art-Figur im Desktop Widget: sitzt am Laptop und tippt – animiert.

- Tipp-Geschwindigkeit spiegelt Companion-Stimmung: happy/proud = schnell, disappointed = langsam
- Kopf-Nicken, Arm-Bewegung, Augen-Blink (alle ~3,5 Sekunden)
- Stimmungs-Indikator über dem Kopf (grün / orange / grau)
- Stimmung basiert auf den letzten 5 Einträgen

| Stimmung | Bedingung |
|----------|-----------|
| worried | 3+ Ablenkung in letzten 5 |
| happy/proud | 4+ produktiv in letzten 5 + guter Streak |
| disappointed | Energy < 20 |
| neutral | Sonst |

### Dopamin-Nudge (DopaminMenu)

Erscheint im Logging-Popup wenn Kategorie "Ablenkung" gewählt wird:

- Kontextuelle Alternativen (z. B. Social Media → 5 min Natur beobachten)
- Aktivitäts-Paarungen (z. B. E-Mails + Kaffee)
- Auto-Dismiss nach 8 Sekunden, manuell schließbar

### Statistiken

Vier Tabs im Statistik-Fenster:

#### Heute
- Tages-Breakdown: Kategorien mit Balkendiagramm, Minuten und Prozent
- Focus Score + Garden
- MissionBar (Produktivziel-Fortschritt)
- Tages-Impuls (Zitat/Bibelvers)
- Best/Worst Hour

#### Woche
- Gestapeltes Balkendiagramm der letzten 7 Tage (Swift Charts)
- Produktiv-Streak-Badge, Kein-Ablenkung-Streak-Badge
- Wochendurchschnitts-Score

#### Heatmap
- GitHub-Stil: Wochentag × Uhrzeit (4 Wochen)
- Zeigt produktivste Tageszeiten

#### Profil
- Level-Badge + Titel, XP-Fortschrittsbalken
- Energy-Balken, Gold, Streak + Shield-Status
- Distraction Debt Anzeige
- Companion-Stimmung
- Achievement-Grid

### Achievement Toast

Erscheint als Overlay über dem MenuBar Popover bei:
- Achievement-Freischaltung: 🏆 Name + XP/Gold-Reward
- Level-Up: ⬆️ neuer Titel

### MissionBar

Fortschrittsbalken für das tägliche Produktivitätsziel:

- **Manuell**: Ziel in Stunden einstellbar (1–8h)
- **Adaptiv**: Automatisch berechnet als 7-Tage-Durchschnitt + 10%

### Desktop Widget (FloatingWidget)

Immer-oben-schwebendes Fenster (260px breit):

- Sichtbar auf allen Spaces (auch in Fullscreen)
- Zeigt: Timer-Countdown, ⚡ FLOW-Badge, Focus Score, Body-Double-Companion, Notizfeld, 3 Kategorie-Buttons
- Distraction-Debt-Banner (rot) wenn Schulden vorhanden
- Letzten Eintrag wiederholen
- Position wird gespeichert

### Datenexport

- **Excel-Export**: Automatisch nach jedem Log als `.xlsx`-Datei im Application Support Verzeichnis
  - Spalten: Datum (DD.MM.YYYY), Uhrzeit (HH:MM), Kategorie, Kommentar, Minuten
  - Farbkodierung: grün (produktiv), grau (neutral), rot (Ablenkung)
- **iCloud Kalender**: Jeder Eintrag wird als Kalender-Event angelegt (3 separate Kalender nach Kategorie)
- **Datenbankbackup**: Export/Import über Einstellungen → Daten

### Systembewusstsein

- **Sleep/Wake**: Popup erscheint sofort nach System-Wake
- **Idle Detection** (IOKit): Erkennt inaktive Mac-Phasen ≥5 Minuten
- **Re-Reminder**: Wenn Popup >5 Minuten ignoriert wird, erneuter Sound
- **Globaler Hotkey**: `Cmd+Shift+T` öffnet Logging-Popup aus jeder App

---

## UI-Design-Prinzipien

- **MenuBar Popover + Desktop Widget**: Helles Design (Off-White Hintergrund, dunkler Text, blauer Akzent)
- **Statistik + Einstellungen**: Dunkles Design (`.preferredColorScheme(.dark)`)
- **Logging-Popup + Intervention**: Dunkel mit blauen Akzentfarben
- **Morning Intention + Evening Debrief**: Helles Design, konsistent mit MenuBar
- Durchgehend deutsche Sprache

---

## Datenstruktur

```
TimeEntry
├── timestamp: Date
├── categoryValue: Int (1=Umsatzgenerierend, 2=Neutral, 3=Ablenkung)
├── note: String (Pflicht)
└── intervalMinutes: Int

DailyIntention
├── date: Date (Tagesbeginn, Mitternacht)
├── priority1/2/3: String
├── avoidance: String
├── priority1/2/3Done: Bool
├── biggestWin: String
├── whatToRepeat: String
└── debriefCompleted: Bool

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
├── companionMoodRaw: String
├── debtMinutes: Int
└── consecutiveProductiveEntries: Int

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

---

## Projektstruktur

```
TimeAudit/
├── TimeAuditApp.swift              # @main, MenuBarExtra-Scene, Timer-Observation
├── AppDelegate.swift               # Lifecycle, Panels, Hotkeys, Monitoring, Timers
│
├── Models/
│   ├── TimeEntry.swift             # Haupt-Datensatz
│   ├── Category.swift              # ActivityCategory enum (3 Kategorien)
│   ├── DailyIntention.swift        # Morning/Evening Intention (SwiftData)
│   ├── AppSettings.swift           # Einstellungen (SwiftData)
│   ├── PlayerProfile.swift         # RPG-Spielerprofil + Debt + Flow State (SwiftData)
│   ├── Achievement.swift           # Achievements (SwiftData)
│   ├── IdentityMode.swift          # Standard/Faith enum
│   └── GameModels.swift            # Level-Schwellen, Nudges, Moods
│
├── ViewModels/
│   ├── TimerViewModel.swift        # Intervall-Timer, Wake-Handling
│   ├── LoggingViewModel.swift      # Kategorie-Auswahl, Smart Defaults, Repeat-Last
│   ├── StatisticsViewModel.swift   # Score, Streaks, Heatmap, Weekly League
│   ├── SettingsViewModel.swift     # Einstellungs-Persistenz
│   ├── IntentionViewModel.swift    # Morning/Evening Intention Logik
│   ├── InterventionViewModel.swift # Micro-Intervention Logik
│   └── GameViewModel.swift         # RPG-State, Flow State, Achievements, Toasts
│
├── Views/
│   ├── MenuBarView.swift           # Haupt-Popover (helles Design)
│   ├── LoggingPopupView.swift      # Logging-Popup (dunkles Design)
│   ├── FloatingWidgetView.swift    # Desktop Widget (helles Design)
│   ├── MorningIntentionView.swift  # Morgen-Prioritäten-Popup
│   ├── EveningDebriefView.swift    # Abend-Debrief-Popup
│   ├── SettingsView.swift          # Einstellungen
│   ├── InterventionView.swift      # Micro-Intervention Popup
│   ├── AchievementToastView.swift  # Achievement/Level-Up Toast
│   ├── ProfileView.swift           # RPG-Profil-Tab
│   └── Statistics/
│       ├── StatisticsView.swift    # Tab-Container
│       ├── DailyOverviewView.swift # Heute-Tab
│       ├── WeeklyChartView.swift   # Woche-Tab
│       └── HeatmapView.swift       # Heatmap-Tab
│
├── Components/
│   ├── FloatingPanel.swift         # NSPanel für Logging-Popup
│   ├── FloatingWidget.swift        # NSPanel für Desktop Widget
│   ├── BodyDoubleView.swift        # Canvas Pixel-Art Companion (44px)
│   ├── GardenView.swift            # Canvas-Garten-Visualisierung
│   ├── MissionBar.swift            # Tagesziel-Fortschrittsbalken
│   ├── FocusScoreView.swift        # Kreisförmiger Score-Indikator
│   ├── StreakBadge.swift           # Streak-Anzeige
│   ├── DailyImpulseView.swift      # Zitat/Bibelvers-Karte
│   ├── DayBlocksView.swift         # Timeline-Blöcke
│   └── CategoryButton.swift        # Kategorie-Auswahl-Button
│
├── Services/
│   ├── GameEngine.swift            # XP/Gold/Energy/Debt/FlowState/Level-Logik
│   ├── IdentityProvider.swift      # Mode-abhängige Strings, Daily Impulses
│   ├── CalendarExporter.swift      # EventKit iCloud Kalender-Integration
│   ├── XLSXWriter.swift            # Pure-Swift .xlsx Auto-Export
│   ├── IdleDetector.swift          # IOKit Idle-Time-Überwachung
│   ├── SleepWakeMonitor.swift      # Sleep/Wake-Events
│   ├── CSVExporter.swift           # CSV-Export (Legacy)
│   └── SoundPlayer.swift           # Benachrichtigungstöne
│
└── Protocols/
    └── GameEngineProtocols.swift   # Interfaces für GameEngine, DopaminMenu, AICompanion
```

---

## Datenfluss

```
App-Start (nach 8:00 Uhr)
  └→ IntentionViewModel.checkMorning()
       └→ MorningIntentionView (wenn noch keine Intention heute)

Eintrag gespeichert (TimeEntry)
  ↓
AppDelegate.onLogSaved()
  ├→ TimerViewModel.didLog()               → Timer zurücksetzen
  ├→ InterventionViewModel.recordCategory() → 2× Ablenkung → Micro-Intervention
  ├→ GameViewModel.processEntry()
  │   ├→ GameEngine.updateStreak()
  │   ├→ GameEngine.applyEntry()
  │   │   ├→ XP (+ Streak-Multiplikator + Flow-State-1,5×)
  │   │   ├→ Gold / Energy
  │   │   ├→ consecutiveProductiveEntries verfolgen
  │   │   └→ Distraction Debt aktualisieren
  │   ├→ GameEngine.checkAchievements()
  │   └→ AICompanion.updateMood()
  ├→ CalendarExporter.createEvent()        → iCloud Kalender
  ├→ XLSXWriter.export()                  → Excel-Datei
  └→ StatisticsViewModel.refresh()
       ├→ computeToday()       → Kategorien-Minuten, Focus Score
       ├→ computeWeekly()      → 7-Tage-Daten
       ├→ computeStreaks()      → Produktiv-Streak, No-Ablenkung-Streak
       ├→ computeBestWorstHour()
       ├→ computeHeatmap()     → 4-Wochen-Grid
       ├→ computeMissionBar()  → Tagesziel-Fortschritt
       └→ computeWeeklyLeague() → Aktuelle vs. vorherige 7 Tage

17:30 Uhr Timer
  └→ IntentionViewModel.checkEvening()
       └→ EveningDebriefView (einmalig, wenn Intention vorhanden + kein Debrief)
```

---

## Tech Stack

- **SwiftUI** + **MenuBarExtra** (macOS 14+)
- **SwiftData** – lokale Persistenz (SQLite)
- **Swift Charts** – Wochen-Balkendiagramm
- **EventKit** – iCloud Kalender-Integration
- **IOKit** – Idle-Time-Erkennung
- **NSPanel** – Floating Panels für Popups und Widget
- **Canvas / GraphicsContext** – Garten + Body-Double-Visualisierung
- **ZIP STORED + Open XML** – Pure-Swift .xlsx Export (keine externen Dependencies)
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
| Kalender-Integration | Autorisierung via Einstellungen | – |

---

## Datenschutz

Alle Daten bleiben **lokal** auf dem Gerät. Keine Cloud, keine externen APIs, kein Tracking. Die iCloud Kalender-Integration nutzt EventKit direkt auf dem Gerät.

---

## Lizenz

Persönliche Nutzung.
