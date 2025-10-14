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
    @Published var currentGames: [GameState] = []
    
    private var overlayWindows: [String: NSWindow] = [:]
    private var timer: Timer?
    private var detailTimers: [String: Timer] = [:]
    private var promptedGames: Set<String> = []
    private var lastPromptDate = ""
    
    func startTracking(teams: [String]) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
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
        
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(todayString)&hydrate=linescore") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                }
                return
            }
            
            guard let data = data else {
                self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dates = json?["dates"] as? [[String: Any]],
                      !dates.isEmpty,
                      let gamesArray = dates.first?["games"] as? [[String: Any]] else {
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                    return
                }
                
                for game in gamesArray {
                    guard let teams = game["teams"] as? [String: Any],
                          let home = (teams["home"] as? [String: Any])?["team"] as? [String: Any],
                          let away = (teams["away"] as? [String: Any])?["team"] as? [String: Any],
                          let homeName = home["name"] as? String,
                          let awayName = away["name"] as? String,
                          let status = game["status"] as? [String: Any],
                          let detailedState = status["detailedState"] as? String else {
                        continue
                    }
                    
                    let isLive = detailedState.contains("In Progress") ||
                                 detailedState.contains("Delayed") ||
                                 detailedState.contains("Warmup")
                    
                    if isLive, trackedTeams.contains(where: {
                        homeName.lowercased().contains($0.lowercased()) ||
                        awayName.lowercased().contains($0.lowercased())
                    }) {
                        let gameID = "\(awayName)_vs_\(homeName)"
                        
                        let linescore = game["linescore"] as? [String: Any]
                        let homeScore = (teams["home"] as? [String: Any])?["score"] as? Int ?? 0
                        let awayScore = (teams["away"] as? [String: Any])?["score"] as? Int ?? 0
                        let inning = linescore?["currentInning"] as? Int ?? 1
                        let inningState = linescore?["inningState"] as? String ?? "Top"
                        let isTop = inningState.lowercased().contains("top")
                        
                        let newGame = GameState(
                            id: gameID,
                            home: homeName,
                            away: awayName,
                            homeScore: homeScore,
                            awayScore: awayScore,
                            inning: inning,
                            isTopInning: isTop,
                            pitcher: "Loading...",
                            pitchCount: 0,
                            batterBalls: 0,
                            batterStrikes: 0,
                            bases: [false, false, false],
                            batter: nil
                        )
                        
                        DispatchQueue.main.async {
                            if let index = self.currentGames.firstIndex(where: { $0.id == gameID }) {
                                self.currentGames[index] = newGame
                            } else {
                                self.currentGames.append(newGame)
                                if !self.promptedGames.contains(gameID) {
                                    self.promptedGames.insert(gameID)
                                    self.promptUserBeforeOverlay(game: newGame)
                                }
                            }
                            
                            if let gamePk = game["gamePk"] as? Int {
                                self.fetchGameDetails(gamePk: gamePk, gameID: gameID)
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    let liveGameIDs = gamesArray.compactMap { game -> String? in
                        guard let teams = game["teams"] as? [String: Any],
                              let home = (teams["home"] as? [String: Any])?["team"] as? [String: Any],
                              let away = (teams["away"] as? [String: Any])?["team"] as? [String: Any],
                              let homeName = home["name"] as? String,
                              let awayName = away["name"] as? String else {
                            return nil
                        }
                        return "\(awayName)_vs_\(homeName)"
                    }
                    
                    self.currentGames.removeAll { game in
                        !liveGameIDs.contains(game.id)
                    }
                    
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                }
            } catch {
                DispatchQueue.main.async {
                    self.injectFakeGameIfNeeded(trackedTeams: trackedTeams)
                }
            }
        }
        
        task.resume()
    }
    
    private func updateGameDetails(game: [String: Any], homeName: String, awayName: String) {
        guard let gamePk = game["gamePk"] as? Int else { return }
        let gameID = "\(awayName)_vs_\(homeName)"
        fetchGameDetails(gamePk: gamePk, gameID: gameID)
    }
    
    private func fetchGameDetails(gamePk: Int, gameID: String) {
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1.1/game/\(gamePk)/feed/live") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let liveData = json?["liveData"] as? [String: Any],
                      let plays = liveData["plays"] as? [String: Any],
                      let currentPlay = plays["currentPlay"] as? [String: Any] else { return }
                
                let matchup = currentPlay["matchup"] as? [String: Any]
                let pitcherData = matchup?["pitcher"] as? [String: Any]
                let pitcherName = pitcherData?["fullName"] as? String ?? "Unknown"
                
                let batterData = matchup?["batter"] as? [String: Any]
                let batterName = batterData?["fullName"] as? String ?? "Unknown"
                
                let batterStats = matchup?["batterStats"] as? [String: Any]
                let avg = batterStats?["avg"] as? String ?? ".000"
                let hits = batterStats?["hits"] as? Int ?? 0
                let atBats = batterStats?["atBats"] as? Int ?? 0
                
                let count = currentPlay["count"] as? [String: Any]
                let balls = count?["balls"] as? Int ?? 0
                let strikes = count?["strikes"] as? Int ?? 0
                
                let runners = currentPlay["runners"] as? [[String: Any]] ?? []
                var bases = [false, false, false]
                for runner in runners {
                    if let movement = runner["movement"] as? [String: Any],
                       let end = movement["end"] as? String {
                        if end == "1B" { bases[0] = true }
                        if end == "2B" { bases[1] = true }
                        if end == "3B" { bases[2] = true }
                    }
                }
                
                DispatchQueue.main.async {
                    if let index = self.currentGames.firstIndex(where: { $0.id == gameID }) {
                        let game = self.currentGames[index]
                        let avgDouble = Double(avg) ?? 0.0
                        self.currentGames[index] = GameState(
                            id: game.id,
                            home: game.home,
                            away: game.away,
                            homeScore: game.homeScore,
                            awayScore: game.awayScore,
                            inning: game.inning,
                            isTopInning: game.isTopInning,
                            pitcher: pitcherName,
                            pitchCount: 0,
                            batterBalls: balls,
                            batterStrikes: strikes,
                            bases: bases,
                            batter: Batter(name: batterName, average: avgDouble, hits: hits, atBats: atBats)
                        )
                    }
                }
            } catch {
                return
            }
        }
        task.resume()
        
        detailTimers[gameID]?.invalidate()
        detailTimers[gameID] = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchGameDetails(gamePk: gamePk, gameID: gameID)
        }
    }
    
    private func injectFakeGameIfNeeded(trackedTeams: [String]) {
        #if DEBUG
        let fakeGames = [
            ("Yankees", "Dodgers", "Los Angeles Dodgers", "New York Yankees", 4, 3),
            ("Blue Jays", "Red Sox", "Boston Red Sox", "Toronto Blue Jays", 2, 5),
            ("Astros", "Rangers", "Texas Rangers", "Houston Astros", 1, 1)
        ]
        
        for (team1, team2, homeFull, awayFull, homeScore, awayScore) in fakeGames {
            guard trackedTeams.contains(where: { team1.contains($0) || team2.contains($0) }) else { continue }
            
            let gameID = "\(awayFull)_vs_\(homeFull)"
            guard !promptedGames.contains(gameID) else { continue }
            promptedGames.insert(gameID)
            
            let newGame = GameState(
                id: gameID,
                home: homeFull,
                away: awayFull,
                homeScore: homeScore,
                awayScore: awayScore,
                inning: Int.random(in: 5...9),
                isTopInning: Bool.random(),
                pitcher: ["Gerrit Cole", "Justin Verlander", "Max Scherzer"].randomElement()!,
                pitchCount: Int.random(in: 60...100),
                batterBalls: Int.random(in: 0...3),
                batterStrikes: Int.random(in: 0...2),
                bases: [Bool.random(), Bool.random(), Bool.random()],
                batter: Batter(
                    name: ["Shohei Ohtani", "Aaron Judge", "Vladimir Guerrero Jr."].randomElement()!,
                    average: Double.random(in: 0.250...0.350),
                    hits: Int.random(in: 0...4),
                    atBats: Int.random(in: 3...5)
                )
            )
            
            DispatchQueue.main.async {
                self.currentGames.append(newGame)
                self.promptUserBeforeOverlay(game: newGame)
            }
        }
        #endif
    }
    
    func showOverlay(for game: GameState) {
        if let existingWindow = overlayWindows[game.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 340
        let height: CGFloat = 220
        let x = screenFrame.maxX - width - 20
        let y = screenFrame.maxY - height - 60 - (CGFloat(overlayWindows.count) * 240)
        
        let overlay = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        overlay.title = "\(game.away) @ \(game.home)"
        overlay.isMovableByWindowBackground = true
        overlay.level = .floating
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(
            rootView: OverlayView(
                game: game,
                closeAction: { [weak self, weak overlay] in
                    overlay?.close()
                    self?.overlayWindows.removeValue(forKey: game.id)
                    self?.detailTimers[game.id]?.invalidate()
                    self?.detailTimers.removeValue(forKey: game.id)
                }
            )
        )
        
        overlay.contentView = hostingView
        overlay.delegate = OverlayWindowDelegate(service: self, gameID: game.id)
        
        overlay.makeKeyAndOrderFront(nil)
        overlayWindows[game.id] = overlay
    }
    
    func closeOverlay(for gameID: String) {
        overlayWindows[gameID]?.close()
        overlayWindows.removeValue(forKey: gameID)
        detailTimers[gameID]?.invalidate()
        detailTimers.removeValue(forKey: gameID)
    }
    
    func promptUserBeforeOverlay(game: GameState) {
        let alert = NSAlert()
        alert.messageText = "\(game.away) @ \(game.home) is LIVE!"
        alert.informativeText = "Do you want to watch the live scorecard?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showOverlay(for: game)
        }
    }
}

class OverlayWindowDelegate: NSObject, NSWindowDelegate {
    let service: MLBStatsService
    let gameID: String
    
    init(service: MLBStatsService, gameID: String) {
        self.service = service
        self.gameID = gameID
    }
    
    func windowWillClose(_ notification: Notification) {
        service.closeOverlay(for: gameID)
    }
}
