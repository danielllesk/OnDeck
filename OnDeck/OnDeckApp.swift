//
//  OnDeckApp.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//

import SwiftUI

@main
struct OnDeckApp: App {
    @StateObject var statsService = MLBStatsService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(statsService)
        }
    }
}
