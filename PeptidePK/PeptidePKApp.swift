//
//  PeptidePKApp.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import SwiftUI
import SwiftData

@main
struct PeptidePKApp: App {
    static let cloudKitContainerIdentifier = "iCloud.com.isaackhor.PeptidePK"

    static let appSchema = Schema([
        Injection.self,
        PKSettings.self,
    ])

    static let previewModelContainer: ModelContainer = {
        makeModelContainer(isStoredInMemoryOnly: true)
    }()

    var sharedModelContainer: ModelContainer = {
        makeModelContainer(isStoredInMemoryOnly: false)
    }()

    static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let modelConfiguration: ModelConfiguration

        if isStoredInMemoryOnly {
            modelConfiguration = ModelConfiguration(
                schema: appSchema,
                isStoredInMemoryOnly: true
            )
        } else {
            modelConfiguration = ModelConfiguration(
                schema: appSchema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        }

        do {
            return try ModelContainer(for: appSchema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

extension PeptidePKApp {
    static func seededPreviewModelContainer() -> ModelContainer {
        let container = makeModelContainer(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let settings = PKSettings()
        context.insert(settings)

        context.insert(Injection(timestamp: Date().addingTimeInterval(-14 * 86_400), drug: .semaglutide, doseMilligrams: 0.5))
        context.insert(Injection(timestamp: Date().addingTimeInterval(-7 * 86_400), drug: .semaglutide, doseMilligrams: 0.5))
        context.insert(Injection(timestamp: Date().addingTimeInterval(-2 * 86_400), drug: .tirzepatide, doseMilligrams: 2.5))

        return container
    }
}
