//
//  SettingsView.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import SwiftData
import SwiftUI

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

#Preview {
    ContentView()
        .modelContainer(PeptidePKApp.previewModelContainer)
}
