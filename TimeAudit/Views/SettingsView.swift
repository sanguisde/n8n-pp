import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Settings View

/// App settings: interval, sound, launch at login, categories.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settingsVM: SettingsViewModel

    @State private var newCategoryName: String = ""
    @State private var backupMessage: String?

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

            Section("Kategorien") {
                Text("Standard-Kategorien sind immer verfuegbar. Hier kannst du weitere hinzufuegen.")
                    .font(.system(size: 11))
                    .foregroundStyle(ThemeColors.textTertiary)

                ForEach(settingsVM.customCategories, id: \.self) { category in
                    HStack {
                        Text(category)
                            .foregroundStyle(ThemeColors.textPrimary)
                        Spacer()
                        Button(role: .destructive) {
                            settingsVM.customCategories.removeAll { $0 == category }
                            settingsVM.save(context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(ThemeColors.dangerAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField("Neue Kategorie", text: $newCategoryName)
                        .textFieldStyle(.roundedBorder)

                    Button("Hinzufuegen") {
                        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        settingsVM.customCategories.append(name)
                        newCategoryName = ""
                        settingsVM.save(context: modelContext)
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
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

                if let msg = backupMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
            }

            Section("Info") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Speicherort", value: "~/Library/Application Support/TimeAudit")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 500)
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
