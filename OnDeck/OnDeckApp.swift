//
//  OnDeckApp.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//

import SwiftUI

@main
struct OnDeckApp: App {
    @StateObject private var statsService = MLBStatsService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(statsService)
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit OnDeck") {
                    statsService.closeAllOverlays()
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            statsService.closeAllOverlays()
        }
    }
}

