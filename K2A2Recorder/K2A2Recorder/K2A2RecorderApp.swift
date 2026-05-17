//
//  K2A2RecorderApp.swift
//  K2A2Recorder
//
//  Created by 樋田一幸 on 2026/05/17.
//

import SwiftUI
import SwiftData

@main
struct K2A2RecorderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            BloodPressureRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
