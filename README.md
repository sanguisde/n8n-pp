# TimeAudit - macOS Menubar Time Tracking App

A minimalist macOS menu bar app built with SwiftUI that serves as a personal "Time Audit Tool". Every 15 minutes, a popup forces you to categorize what you did - building awareness of how you spend your time.

## Features

### Core
- **Menu bar only** - runs silently in the background, no dock icon
- **15-minute popup timer** - cannot be dismissed without selecting a category
- **11 pre-built categories** with color coding and keyboard shortcuts (1-9, 0, -)
- **Optional notes and project tags** per entry
- **Dark minimalist UI** optimized for speed

### Smart Features
- **Focus Score** (0-100) - daily productivity score based on category weights
- **Streak Tracking** - consecutive productive days and distraction-free days
- **Smart Defaults** - pre-selects category if you logged the same one 3x in a row
- **Idle Detection** - suggests "Pause" or "Schlaf" when Mac was idle
- **Menu bar indicator** - colored dot shows last category's productivity level
- **Wake-from-sleep detection** - immediate popup after Mac wakes up
- **Re-reminder** - plays sound again if popup is open for > 5 minutes

### Statistics
- **Daily overview** - time per category with percentages and bar chart
- **Weekly chart** - stacked bar chart per day (Swift Charts)
- **Heatmap** - GitHub-style activity grid (weekday x hour)
- **Best/Worst Hour** - auto-detected most/least productive times
- **Day comparison** - today's score vs. 7-day average

### Extras
- **CSV Export** to ~/Documents
- **Global hotkey** Cmd+Shift+T to open logging window anytime
- **Launch at Login** via SMAppService
- **Database backup/restore** from Settings
- **Configurable interval** (15 / 30 / 60 minutes)
- **Notification sound** (toggleable)

## Categories

| # | Category | Productivity Weight |
|---|----------|-------------------|
| 1 | Revenue Generating | +1.0 |
| 2 | Strategisch | +0.7 |
| 3 | Deep Work | +1.0 |
| 4 | Admin | 0.0 |
| 5 | Konsum | -0.5 |
| 6 | Ablenkung | -1.0 |
| 7 | Pause | 0.0 |
| 8 | Training | +0.3 |
| 9 | Schlaf | 0.0 |
| 0 | Beziehung / Social | 0.0 |
| - | Sonstiges | 0.0 |

## Tech Stack

- **SwiftUI** + **MenuBarExtra** (macOS 14+)
- **SwiftData** for local persistence
- **Swift Charts** for statistics visualizations
- **IOKit** for idle time detection
- **SMAppService** for launch at login
- **NSPanel** subclass for floating popup window
- **MVVM** architecture

## Setup in Xcode

1. **Open Xcode** (16.0+)
2. **File > New > Project > macOS > App**
   - Product Name: `TimeAudit`
   - Interface: SwiftUI
   - Storage: SwiftData
   - Language: Swift
3. **Delete** the auto-generated files (ContentView.swift, Item.swift, TimeAuditApp.swift)
4. **Copy** all files from `TimeAudit/` into the Xcode project:
   - Drag the folder contents into the Xcode project navigator
   - Ensure "Copy items if needed" is checked
   - Ensure target membership is set to `TimeAudit`
5. **Set Info.plist**:
   - Select the target > Info tab
   - Add `Application is agent (UIElement)` = `YES`
   - Or set `LSUIElement` = `true` in Info.plist
6. **Set deployment target** to macOS 14.0
7. **Add frameworks** (should be auto-linked):
   - Charts
   - SwiftData
   - ServiceManagement
   - IOKit
8. **Build and Run** (Cmd+R)

### Optional: Add KeyboardShortcuts package
For user-customizable global hotkeys (currently uses NSEvent monitors):
1. File > Add Package Dependencies
2. URL: `https://github.com/sindresorhus/KeyboardShortcuts`
3. Follow package integration instructions

## Project Structure

```
TimeAudit/
├── TimeAuditApp.swift          # @main entry, MenuBarExtra scene
├── AppDelegate.swift           # Panel management, monitors, hotkeys
├── Models/
│   ├── Category.swift          # ActivityCategory enum
│   ├── TimeEntry.swift         # SwiftData model
│   └── AppSettings.swift       # SwiftData settings model
├── ViewModels/
│   ├── TimerViewModel.swift    # Timer, wake detection, reminders
│   ├── LoggingViewModel.swift  # Category selection, smart defaults
│   ├── StatisticsViewModel.swift # Aggregation, scoring, analysis
│   └── SettingsViewModel.swift # Settings management
├── Views/
│   ├── MenuBarView.swift       # Main popover view
│   ├── LoggingPopupView.swift  # 15-min popup
│   ├── SettingsView.swift      # Settings form
│   └── Statistics/
│       ├── StatisticsView.swift    # Tab container
│       ├── DailyOverviewView.swift # Today's breakdown
│       ├── WeeklyChartView.swift   # Weekly bar chart
│       └── HeatmapView.swift      # Activity heatmap
├── Components/
│   ├── FloatingPanel.swift     # NSPanel subclass
│   ├── CategoryButton.swift    # Category selection button
│   ├── FocusScoreView.swift    # Circular score indicator
│   └── StreakBadge.swift       # Streak display
├── Services/
│   ├── IdleDetector.swift      # IOKit idle time
│   ├── SleepWakeMonitor.swift  # Sleep/wake events
│   ├── CSVExporter.swift       # CSV export
│   └── SoundPlayer.swift      # Notification sounds
└── Resources/
    └── Assets.xcassets         # App icon
```

## Data Storage

All data is stored locally in `~/Library/Application Support/TimeAudit/` via SwiftData (SQLite under the hood). No cloud, no external APIs.

## License

Personal use.
