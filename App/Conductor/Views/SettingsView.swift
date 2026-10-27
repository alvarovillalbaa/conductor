import SwiftUI
import UIKit

@MainActor
struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    let store: ConductorStore

    var body: some View {
        Form {
            if store.isReadOnly { RecoverySection(store: store) }
            if store.notice != nil { Section { NoticeView(store: store) } }
            Section {
                LabeledContent("Conductor preference", value: store.workspace.remindersEnabled ? "On" : "Off")
                LabeledContent("iOS permission", value: store.reminderUpdate?.permission ?? "Checking…")
                if let update = store.reminderUpdate {
                    Text(update.message).font(.callout).foregroundStyle(update.isError ? Color.orange : Color.secondary)
                }
                if store.workspace.remindersEnabled {
                    Button("Turn Reminders Off") { store.disableReminders() }.disabled(store.isReadOnly)
                } else {
                    Button(store.isRequestingPermission ? "Waiting for iOS…" : "Enable Reminders") { store.enableReminders() }
                        .disabled(store.isReadOnly || store.isRequestingPermission)
                }
                Button("Refresh Reminder Status") { store.reconcileReminders() }
                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            } header: {
                Text("Local reminders")
            } footer: {
                Text("Only future start and time-elapsed cues are requested. Past cues stay in the app and are not replayed. iOS may suppress sounds or delay delivery; Conductor does not run a continuous background timer.")
            }
            Section("Your data") {
                DataExportButton(title: "Export Saved Workspace") { try store.exportCurrent() }.disabled(store.isReadOnly)
                if store.unsavedData != nil {
                    DataExportButton(title: "Export Last Save Attempt") { try store.exportUnsaved() }
                    Text("This is the captured snapshot from a failed save, not a live copy of an open editing form.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Plans and the current run stay on this device. Exported JSON is a data copy for manual recovery; this version does not import backups.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("About the timing") {
                Text("All planned starts work backward from one absolute target. Actual starts, pauses and completion are your actions. Device clock changes affect estimates, and changing a plan does not change an existing run.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("No account, cloud service or model provider is used.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

@MainActor
struct RecoverySection: View {
    let store: ConductorStore

    var body: some View {
        Section("Saved data needs recovery") {
            Text(store.recoveryMessage ?? "The saved file could not be opened.").foregroundStyle(.orange).textSelection(.enabled)
            Text("The original file is unchanged. Editing and run actions are paused until a complete reread succeeds.")
                .font(.callout)
            DataExportButton(title: "Export Original File") { try store.exportOriginal() }
            Button("Try Loading Again") { store.reloadSavedData() }
        }
    }
}
