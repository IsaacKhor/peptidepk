//
//  SettingsView.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import SwiftData
import SwiftUI
import CloudKit

struct SettingsView: View {
    var settings: PKSettings?

    var body: some View {
        NavigationStack {
            Group {
                if let settings {
                    SettingsForm(settings: settings)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SettingsForm: View {
    @Bindable var settings: PKSettings

    private var displayMode: Binding<PKDisplayMode> {
        Binding {
            settings.displayMode
        } set: { newValue in
            settings.displayMode = newValue
        }
    }

    var body: some View {
        Form {
            SyncStatusSection()

            Section("Display") {
                Picker("Units", selection: displayMode) {
                    ForEach(PKDisplayMode.allCases) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Body") {
                Stepper(value: $settings.bodyWeightKilograms, in: 30...250, step: 0.5) {
                    LabeledContent("Weight", value: "\(settings.bodyWeightKilograms.formatted(.number.precision(.fractionLength(1)))) kg")
                }
            }

            Section("Graph") {
                Stepper(value: $settings.graphPastDays, in: 7...180, step: 7) {
                    LabeledContent("Past", value: "\(Int(settings.graphPastDays)) days")
                }

                Stepper(value: $settings.graphFutureDays, in: 7...180, step: 7) {
                    LabeledContent("Future", value: "\(Int(settings.graphFutureDays)) days")
                }
            }
        }
    }
}

private struct SyncStatusSection: View {
    @Environment(\.modelContext) private var modelContext

    @State private var status: CKAccountStatus?
    @State private var isChecking = false
    @State private var lastErrorDescription: String?
    @AppStorage("lastSyncAttemptTimestamp") private var lastSyncAttemptTimestamp: Double = 0

    var body: some View {
        Section("iCloud Sync") {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(statusTitle)

                Spacer()

                if isChecking {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let lastErrorDescription {
                Text(lastErrorDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await syncNow()
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isChecking ? "Syncing..." : "Sync Now")
                    Text("Status: \(shortStatusTitle) • Last sync: \(lastSyncDisplayText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isChecking)
        }
        .task {
            if status == nil && !isChecking {
                await fetchStatus()
            }
        }
    }

    private var shortStatusTitle: String {
        switch status {
        case .available:
            "Available"
        case .noAccount:
            "No Account"
        case .restricted:
            "Restricted"
        case .couldNotDetermine:
            "Unknown"
        case .temporarilyUnavailable:
            "Unavailable"
        case .none:
            "Unknown"
        @unknown default:
            "Unknown"
        }
    }

    private var lastSyncDisplayText: String {
        guard lastSyncAttemptTimestamp > 0 else { return "Never" }
        return Date(timeIntervalSince1970: lastSyncAttemptTimestamp)
            .formatted(date: .abbreviated, time: .shortened)
    }

    private var statusTitle: String {
        if isChecking && status == nil {
            return "Checking..."
        }

        switch status {
        case .available:
            return "Available - syncing with iCloud"
        case .noAccount:
            return "Not signed in to iCloud"
        case .restricted:
            return "Restricted on this device"
        case .couldNotDetermine:
            return "Could not determine status"
        case .temporarilyUnavailable:
            return "Temporarily unavailable"
        case .none:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch status {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .orange
        case .couldNotDetermine, .temporarilyUnavailable, .none:
            return .gray
        @unknown default:
            return .gray
        }
    }

    private func syncNow() async {
        isChecking = true
        lastErrorDescription = nil

        do {
            // Force local persistence so SwiftData has fresh changes to sync.
            try modelContext.save()
            lastSyncAttemptTimestamp = Date().timeIntervalSince1970
        } catch {
            lastErrorDescription = "Save error: \(error.localizedDescription)"
        }

        await refreshStatus()
        isChecking = false
    }

    private func fetchStatus() async {
        isChecking = true
        await refreshStatus()
        isChecking = false
    }

    private func refreshStatus() async {
        do {
            let accountStatus = try await CKContainer(identifier: PeptidePKApp.cloudKitContainerIdentifier).accountStatus()
            status = accountStatus
        } catch {
            status = .couldNotDetermine
            lastErrorDescription = "CloudKit error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PeptidePKApp.previewModelContainer)
}
