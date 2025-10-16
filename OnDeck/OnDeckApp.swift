//
//  OnDeckApp.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI
import AppKit

@main
struct OnDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

