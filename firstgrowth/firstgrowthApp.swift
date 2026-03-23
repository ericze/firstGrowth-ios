//
//  firstgrowthApp.swift
//  firstgrowth
//
//  Created by ze on 21/3/26.
//

import SwiftUI
import SwiftData

@main
struct firstgrowthApp: App {
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    private static func makeSharedModelContainer() -> ModelContainer {
        let schema = Schema([
            RecordItem.self,
            MemoryEntry.self,
            WeeklyLetter.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                TestHostView()
            } else {
                ContentView()
            }
        }
        .modelContainer(Self.makeSharedModelContainer())
    }
}

private struct TestHostView: View {
    var body: some View {
        Color.clear
    }
}
