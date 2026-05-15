//
//  ContentView.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PKSettings.createdAt, order: .forward) private var settingsRecords: [PKSettings]

    private var settings: PKSettings? {
        settingsRecords.first
    }

    var body: some View {
        TabView {
            ConcentrationView(settings: settings)
                .tabItem {
                    Label("Levels", systemImage: "chart.xyaxis.line")
                }

            InjectionLogView()
                .tabItem {
                    Label("Log", systemImage: "syringe")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            ensureSettingsRecord()
        }
    }

    private func ensureSettingsRecord() {
        guard settingsRecords.isEmpty else { return }
        modelContext.insert(PKSettings())
    }
}

#Preview {
    ContentView()
        .modelContainer(PeptidePKApp.previewModelContainer)
}
