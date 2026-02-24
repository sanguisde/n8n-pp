import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import EventKit

// MARK: - Settings View

/// App settings: interval, sound, identity mode, daily goal, launch at login.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settingsVM: SettingsViewModel
    let identityProvider: IdentityProvider

    @State private var backupMessage: String?
    @State private var showResetTodayConfirmation: Bool = false
    @State private var calendarAuthorized: Bool = CalendarExporter.shared.isAuthorized

    var body: some View {
        Form {
            Section("Timer") {
                Picker("Intervall", selection: $settingsVM.intervalMinutes) {
                    ForEach(settingsVM.intervalOptions, id: \.self) { option in
                        Text("\(option) Minuten").tag(option)
                    }
                }

                Toggle("Benachrichtigungston", isOn: $settingsVM.soundEnabled)
            }

            Section("Identitaet") {
                Picker("Modus", selection: $settingsVM.identityMode) {
                    ForEach(IdentityMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .onChange(of: settingsVM.identityMode) {
                    identityProvider.mode = settingsVM.identityMode
                    settingsVM.save(context: modelContext)
                }

                Text(settingsVM.identityMode.description)
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.textTertiary)
            }

            Section("Tagesziel") {
                Toggle("Adaptives Ziel (7-Tage-Ø + 10%)", isOn: $settingsVM.useAdaptiveGoal)
                    .onChange(of: settingsVM.useAdaptiveGoal) {
                        settingsVM.save(context: modelContext)
                    }

                if !settingsVM.useAdaptiveGoal {
                    Picker("Ziel (Stunden)", selection: $settingsVM.dailyGoalHours) {
                        ForEach(AppSettings.dailyGoalHourOptions, id: \.self) { hours in
                            Text("\(hours) Stunden").tag(hours)
                        }
                    }
                    .onChange(of: settingsVM.dailyGoalHours) {
                        settingsVM.save(context: modelContext)
                    }
                }

                Text(settingsVM.useAdaptiveGoal
                    ? "Das Ziel wird automatisch aus deinem 7-Tage-Durchschnitt + 10% berechnet."
                    : "Manuelles Tagesziel fuer produktive Arbeit (Kategorie 1).")
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.textTertiary)
            }

            Section("System") {
                Toggle("Bei Anmeldung starten", isOn: $settingsVM.launchAtLogin)
                    .onChange(of: settingsVM.launchAtLogin) {
                        settingsVM.toggleLaunchAtLogin()
                    }

                Toggle("Desktop Widget anzeigen", isOn: $settingsVM.widgetEnabled)
                    .onChange(of: settingsVM.widgetEnabled) {
                        settingsVM.save(context: modelContext)
                    }
            }

            Section("Daten") {
                HStack {
                    Button("Datenbank sichern") {
                        backupDatabase()
                    }

                    Button("Datenbank wiederherstellen") {
                        restoreDatabase()
                    }
                }

                Button("Heutige Einträge zurücksetzen") {
                    showResetTodayConfirmation = true
                }
                .foregroundStyle(.red)
                .confirmationDialog(
                    "Alle Einträge von heute löschen?",
                    isPresented: $showResetTodayConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Zurücksetzen", role: .destructive) {
                        resetToday()
                    }
                    Button("Abbrechen", role: .cancel) {}
                } message: {
                    Text("Dieser Vorgang kann nicht rückgängig gemacht werden.")
                }

                if let msg = backupMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
            }

            Section("Integrationen") {
                // --- Kalender ---
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Kalender")
                            .font(.system(size: 12, weight: .medium))
                        Text(calendarAuthorized
                             ? "Aktiv – neue Einträge werden als Kalenderevents angelegt"
                             : "Kalender-Zugriff noch nicht erteilt")
                            .font(.system(size: 10))
                            .foregroundStyle(ThemeColors.textTertiary)
                    }
                    Spacer()
                    if calendarAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Zugriff erlauben") {
                            CalendarExporter.shared.requestAccess { granted in
                                calendarAuthorized = granted
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                // --- Excel ---
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Excel-Protokoll")
                            .font(.system(size: 12, weight: .medium))
                        Text("Wird nach jedem Eintrag automatisch aktualisiert")
                            .font(.system(size: 10))
                            .foregroundStyle(ThemeColors.textTertiary)
                    }
                    Spacer()
                    Button("Im Finder zeigen") {
                        NSWorkspace.shared.activateFileViewerSelecting(
                            [XLSXWriter.shared.exportURL]
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section("Info") {
                LabeledContent("Version", value: "2.0.0")
                LabeledContent("Speicherort", value: "~/Library/Application Support/TimeAudit")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 550)
        .background(ThemeColors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            settingsVM.load(context: modelContext)
        }
        .onChange(of: settingsVM.intervalMinutes) {
            settingsVM.save(context: modelContext)
        }
        .onChange(of: settingsVM.soundEnabled) {
            settingsVM.save(context: modelContext)
        }
    }

    // MARK: - Backup / Restore

    private func resetToday() {
        let descriptor = FetchDescriptor<TimeEntry>()
        guard let entries = try? modelContext.fetch(descriptor) else { return }
        let todayEntries = entries.filter { Calendar.current.isDateInToday($0.timestamp) }
        for entry in todayEntries {
            modelContext.delete(entry)
        }
        backupMessage = "\(todayEntries.count) Einträge gelöscht"
    }

    private func backupDatabase() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("TimeAudit")

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "TimeAudit_Backup_\(dateString()).sqlite"
        panel.allowedContentTypes = [.data]

        if panel.runModal() == .OK, let url = panel.url {
            let dbFile = dbDir.appendingPathComponent("default.store")
            do {
                try FileManager.default.copyItem(at: dbFile, to: url)
                backupMessage = "Backup erstellt"
            } catch {
                backupMessage = "Backup fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func restoreDatabase() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbDir = appSupport.appendingPathComponent("TimeAudit")
            let dbFile = dbDir.appendingPathComponent("default.store")

            do {
                if FileManager.default.fileExists(atPath: dbFile.path) {
                    try FileManager.default.removeItem(at: dbFile)
                }
                try FileManager.default.copyItem(at: url, to: dbFile)
                backupMessage = "Wiederherstellung erfolgreich. Bitte App neu starten."
            } catch {
                backupMessage = "Wiederherstellung fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }
}
