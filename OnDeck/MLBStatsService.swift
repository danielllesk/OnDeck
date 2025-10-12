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
    
    func checkForLiveGames(trackedTeams: [String]) {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(today)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dates = json?["dates"] as? [[String: Any]],
                      let gamesArray = dates.first?["games"] as? [[String: Any]] else { return }
                
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
                        
                        DispatchQueue.main.async {
                            self.currentGame = GameState(home: homeName, away: awayName)
                            self.promptUserBeforeOverlay(game: self.currentGame!)
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.currentGame = nil
                    self.closeOverlay()
                }
            } catch {
                print("Error: \(error)")
            }
        }.resume()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentGame = GameState(home: "Blue Jays", away: "Yankees", homeScore: 3, awayScore: 4, inning: 9)
            self.showOverlay()
        }
    }
    
    func showOverlay() {
        guard overlayWindow == nil else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x:0, y:0, width:1440, height:900)
        let width: CGFloat = 260
        let height: CGFloat = 120
        let x = screenFrame.maxX - width - 20   // 20 pts from right edge
        let y = screenFrame.maxY - height - 40  // 40 pts from top
        
        let overlay = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .floating
        overlay.contentView = NSHostingView(rootView: OverlayView(game: currentGame!, closeAction: { self.closeOverlay() }))
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

}
