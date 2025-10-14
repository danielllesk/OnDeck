//
//  MLBStatsService.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import Foundation
import AppKit
import SwiftUI

class MLBStatsService: ObservableObject {
    @Published var currentGame: GameState?
    
    private var overlayWindow: NSWindow?
    private var timer: Timer?
    private var promptedGames: Set<String> = []
    private var lastPromptDate = ""
    
    
    func startTracking(teams: [String]) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.resetPromptedGamesIfNewDay()
            self?.checkForLiveGames(trackedTeams: teams)
        }
        timer?.fire()
    }
        
    private func resetPromptedGamesIfNewDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        if today != lastPromptDate {
            promptedGames.removeAll()
            lastPromptDate = today
        }
    }
    
    
    private func checkForLiveGames(trackedTeams: [String]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(todayString)") else { return }
        
        print("Fetching MLB schedule: \(url)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Network error fetching MLB schedule: \(error.localizedDescription)")
                self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                return
            }
            
            guard let data = data else {
                print("No data received")
                self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dates = json?["dates"] as? [[String: Any]],
                      let gamesArray = dates.first?["games"] as? [[String: Any]] else {
                    print("No games today")
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                    return
                }
                
                for game in gamesArray {
                    if let teams = game["teams"] as? [String: Any],
                       let home = (teams["home"] as? [String: Any])?["team"] as? [String: Any],
                       let away = (teams["away"] as? [String: Any])?["team"] as? [String: Any],
                       let homeName = home["teamName"] as? String,
                       let awayName = away["teamName"] as? String,
                       let status = game["status"] as? [String: Any],
                       let state = status["abstractGameState"] as? String,
                       state == "Live",
                       trackedTeams.contains(where: { homeName.contains($0) || awayName.contains($0) }) {
                        
                        let gameID = "\(homeName)_vs_\(awayName)"
                        guard !self.promptedGames.contains(gameID) else { return }
                        
                        DispatchQueue.main.async {
                            self.promptedGames.insert(gameID)
                            self.currentGame = GameState(
                                home: homeName,
                                away: awayName,
                                homeScore: 0,
                                awayScore: 0,
                                inning: 1,
                                isTopInning: true,
                                bases: [false, false, false],
                                pitcher: "TBD",
                                pitchCount: 0,
                                batter: "TBD",
                                batterBalls: 0,
                                batterStrikes: 0,
                                batterRecord: "0-0"
                            )
                            self.promptUserBeforeOverlay(game: self.currentGame!)
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.currentGame = nil
                    self.closeOverlay()
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
            }
        }
        
        task.resume()
    }
    
    
    private func injectFakeGameIfNeeded(trackedTeams: [String]) {
        let fakeTeams = ["Yankees", "Dodgers"]
        guard trackedTeams.contains(where: { fakeTeams.contains($0) }) else { return }
        
        let gameID = "Dodgers_vs_Yankees"
        guard !promptedGames.contains(gameID) else { return }
        promptedGames.insert(gameID)
        
        DispatchQueue.main.async {
            self.currentGame = GameState(
                home: "Dodgers",
                away: "Yankees",
                homeScore: 4,
                awayScore: 3,
                inning: 7,
                isTopInning: true,
                bases: [true, false, true],
                pitcher: "Gerrit Cole",
                pitchCount: 85,
                batter: "Shohei Ohtani",
                batterBalls: 1,
                batterStrikes: 2,
                batterRecord: "2-4"
            )
            self.promptUserBeforeOverlay(game: self.currentGame!)
        }
    }
    
    
    func showOverlay() {
        guard overlayWindow == nil else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 260
        let height: CGFloat = 120
        let x = screenFrame.maxX - width - 20
        let y = screenFrame.maxY - height - 40
        
        let overlay = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        
        overlay.contentView = NSHostingView(
            rootView: OverlayView(
                game: currentGame!,
                closeAction: { [weak self] in self?.closeOverlay() }
            )
        )
        
        overlay.makeKeyAndOrderFront(nil)
        overlayWindow = overlay
    }
    
    func closeOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
    }
        
    func promptUserBeforeOverlay(game: GameState) {
        let alert = NSAlert()
        alert.messageText = "\(game.home) vs \(game.away) is live now!"
        alert.informativeText = "Do you want to watch the live scorecard?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showOverlay()
        }
    }
    func showOverlayIfNotVisible() {
        if overlayWindow == nil, let _ = currentGame {
            showOverlay()
        }
    }
}

