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
    @Published var selectedTeams: [String] = []
    @AppStorage("developerModeEnabled") private var developerModeEnabled = false
    private var overlayWindows: [String: NSWindow] = [:]
    private var overlayDelegates: [String: OverlayWindowDelegate] = [:]
    private var closingOverlayIDs: Set<String> = []
    private var timer: Timer?
    private var detailTimers: [String: Timer] = [:]
    private var promptedGames: Set<String> = []
    private var lastPromptDate = ""
    private var spaceChangeTimer: Timer?

    func startTracking(teams: [String]) {
        selectedTeams = teams
        closeAllOverlays()
        timer?.invalidate()
        spaceChangeTimer?.invalidate()
        detailTimers.values.forEach { $0.invalidate() }
        detailTimers.removeAll()
        currentGames.removeAll()
        promptedGames.removeAll()
        
        spaceChangeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.keepOverlaysOnTop()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.resetPromptedGamesIfNewDay()
            self?.checkForLiveGames(trackedTeams: self?.selectedTeams ?? [])
        }
        timer?.fire()
    }
    
    func startTrackingIfNeeded() {
        if !selectedTeams.isEmpty {
            startTracking(teams: selectedTeams)
        }
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

    private func keepOverlaysOnTop() {
        for (_, window) in overlayWindows {
            window.orderFront(nil)
            
            // make sire it's on all spaces
            if !window.collectionBehavior.contains(.canJoinAllSpaces) {
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }

    private func checkForLiveGames(trackedTeams: [String]) {
        guard !trackedTeams.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(todayString)&hydrate=linescore") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.injectFakeGameIfNeeded(trackedTeams: self.selectedTeams)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.injectFakeGameIfNeeded(trackedTeams: self.selectedTeams)
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let dates = json?["dates"] as? [[String: Any]],
                      !dates.isEmpty,
                      let gamesArray = dates.first?["games"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.injectFakeGameIfNeeded(trackedTeams: self.selectedTeams)
                    }
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

                    if isLive,
                       selectedTeams.contains(where: {
                           homeName.lowercased().contains($0.lowercased()) ||
                           awayName.lowercased().contains($0.lowercased())
                       }) {

                        let gameID = "\(awayName)_vs_\(homeName)"
                        let linescore = game["linescore"] as? [String: Any]
                        let homeScore = (teams["home"] as? [String: Any])?["score"] as? Int ?? 0
                        let awayScore = (teams["away"] as? [String: Any])?["score"] as? Int ?? 0
                        let inning = linescore?["currentInning"] as? Int ?? 1
                        let isTop = linescore?["isTopInning"] as? Bool ?? true

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
                            batter: nil,
                            status: detailedState,
                            outs: 0
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

                    self.injectFakeGameIfNeeded(trackedTeams: self.selectedTeams)
                }
            } catch {
                DispatchQueue.main.async {
                    self.injectFakeGameIfNeeded(trackedTeams: self.selectedTeams)
                }
            }
        }
        task.resume()
    }

    private func fetchGameDetails(gamePk: Int, gameID: String) {
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1.1/game/\(gamePk)/feed/live") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard
                    let liveData = json?["liveData"] as? [String: Any],
                    let plays = liveData["plays"] as? [String: Any],
                    let currentPlay = plays["currentPlay"] as? [String: Any],
                    let matchup = currentPlay["matchup"] as? [String: Any],
                    let linescore = liveData["linescore"] as? [String: Any]
                else { return }

                let pitcherData = matchup["pitcher"] as? [String: Any]
                let pitcherName = pitcherData?["fullName"] as? String ?? "Unknown Pitcher"
                let pitcherID = pitcherData?["id"] as? Int ?? 0
                
                let batterData = matchup["batter"] as? [String: Any]
                let batterName = batterData?["fullName"] as? String ?? "Unknown Batter"
                let batterID = batterData?["id"] as? Int ?? 0

                let boxscore = liveData["boxscore"] as? [String: Any]
                let teams = boxscore?["teams"] as? [String: Any]
                
                let inningState = linescore["inningState"] as? String ?? "Top"
                let isTopInning = inningState.lowercased().contains("top")
                let battingTeam = isTopInning ? "away" : "home"
                let pitchingTeam = isTopInning ? "home" : "away"
                
                var pitchCount = 0
                if let pitchingTeamData = teams?[pitchingTeam] as? [String: Any],
                   let pitchers = pitchingTeamData["pitchers"] as? [Int],
                   pitchers.contains(pitcherID),
                   let players = pitchingTeamData["players"] as? [String: Any] {
                    let pitcherKey = "ID\(pitcherID)"
                    if let pitcher = players[pitcherKey] as? [String: Any],
                       let stats = pitcher["stats"] as? [String: Any],
                       let pitching = stats["pitching"] as? [String: Any] {
                        pitchCount = pitching["numberOfPitches"] as? Int ?? 0
                    }
                }

                var seasonAvg = 0.0
                var hits = 0
                var atBats = 0
                
                if let battingTeamData = teams?[battingTeam] as? [String: Any],
                   let batters = battingTeamData["batters"] as? [Int],
                   batters.contains(batterID),
                   let players = battingTeamData["players"] as? [String: Any] {
                    let batterKey = "ID\(batterID)"
                    if let batter = players[batterKey] as? [String: Any],
                       let stats = batter["stats"] as? [String: Any],
                       let batting = stats["batting"] as? [String: Any] {
                        hits = batting["hits"] as? Int ?? 0
                        atBats = batting["atBats"] as? Int ?? 0
                        
                        if let avg = batting["avg"] as? String {
                            seasonAvg = Double(avg) ?? 0.0
                        }
                    }
                    
                    if seasonAvg == 0.0, let batter = players[batterKey] as? [String: Any],
                       let seasonStats = batter["seasonStats"] as? [String: Any],
                       let batting = seasonStats["batting"] as? [String: Any],
                       let avg = batting["avg"] as? String {
                        seasonAvg = Double(avg) ?? 0.0
                    }
                }

                let count = (currentPlay["count"] as? [String: Any]) ?? [:]
                let balls = count["balls"] as? Int ?? 0
                let strikes = count["strikes"] as? Int ?? 0

                let outs = linescore["outs"] as? Int ?? 0
                let inning = linescore["currentInning"] as? Int ?? 1

                var bases = [false, false, false]
                if let offense = linescore["offense"] as? [String: Any] {
                    if let first = offense["first"] as? [String: Any], first["id"] != nil {
                        bases[0] = true
                    }
                    if let second = offense["second"] as? [String: Any], second["id"] != nil {
                        bases[1] = true
                    }
                    if let third = offense["third"] as? [String: Any], third["id"] != nil {
                        bases[2] = true
                    }
                }

                DispatchQueue.main.async {
                    if let index = self.currentGames.firstIndex(where: { $0.id == gameID }) {
                        let game = self.currentGames[index]
                        self.currentGames[index] = GameState(
                            id: game.id,
                            home: game.home,
                            away: game.away,
                            homeScore: game.homeScore,
                            awayScore: game.awayScore,
                            inning: inning,
                            isTopInning: isTopInning,
                            pitcher: pitcherName,
                            pitchCount: pitchCount,
                            batterBalls: balls,
                            batterStrikes: strikes,
                            bases: bases,
                            batter: Batter(
                                name: batterName,
                                average: seasonAvg,
                                hits: hits,
                                atBats: atBats
                            ),
                            status: game.status,
                            outs: outs
                        )
                    }
                }
            } catch {
                print("Error parsing details for \(gameID): \(error)")
            }
        }

        task.resume()

        detailTimers[gameID]?.invalidate()
        detailTimers[gameID] = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchGameDetails(gamePk: gamePk, gameID: gameID)
        }
    }

    public func refreshNow(gameID: String) {
        guard let game = currentGames.first(where: { $0.id == gameID }) else { return }
        checkForLiveGames(trackedTeams: selectedTeams)
    }

    func showOverlay(for game: GameState) {
        if let existingWindow = overlayWindows[game.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let activeScreen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let screenFrame = activeScreen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        let width: CGFloat = 340
        let height: CGFloat = 240
        let x = screenFrame.maxX - width - 20
        let y = screenFrame.maxY - height - 60 - (CGFloat(overlayWindows.count) * 250)

        // Nspanel instead of window(this the reason)
        let overlay = NSPanel(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        overlay.title = "\(game.away) @ \(game.home)"
        overlay.isMovableByWindowBackground = true
        
        overlay.isFloatingPanel = true
        overlay.level = .floating
        overlay.becomesKeyOnlyIfNeeded = true
        overlay.worksWhenModal = false
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        overlay.hidesOnDeactivate = false
        overlay.isReleasedWhenClosed = false

        let hostingView = NSHostingView(
            rootView: OverlayView(
                service: self,
                gameID: game.id,
                closeAction: { [weak self] in
                    self?.closeOverlay(for: game.id)
                }
            )
        )
        overlay.contentView = hostingView
        overlay.isOpaque = true
        overlay.backgroundColor = NSColor.windowBackgroundColor
        
        let delegate = OverlayWindowDelegate(service: self, gameID: game.id)
        overlay.delegate = delegate
        overlay.orderFront(nil)
        
        overlayWindows[game.id] = overlay
        overlayDelegates[game.id] = delegate
    }

    func closeAllOverlays() {
        for (id, window) in overlayWindows {
            closingOverlayIDs.insert(id)
            window.performClose(nil)
            detailTimers[id]?.invalidate()
        }
        for id in Array(overlayWindows.keys) {
            cleanupOverlay(for: id)
        }
    }

    func closeOverlay(for gameID: String) {
        guard let window = overlayWindows[gameID] else { return }
        if closingOverlayIDs.contains(gameID) { return }
        closingOverlayIDs.insert(gameID)
        window.performClose(nil)
    }

    func cleanupOverlay(for gameID: String) {
        if let window = overlayWindows[gameID] {
            window.delegate = nil
            window.contentView = nil
        }
        overlayWindows.removeValue(forKey: gameID)
        detailTimers[gameID]?.invalidate()
        detailTimers.removeValue(forKey: gameID)
        overlayDelegates.removeValue(forKey: gameID)
        closingOverlayIDs.remove(gameID)
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

    private func injectFakeGameIfNeeded(trackedTeams: [String]) {
        guard developerModeEnabled, currentGames.isEmpty else { return }
        guard !trackedTeams.isEmpty else { return }
        
        let normalizedTracked = Set(trackedTeams.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })

        let fakeGames = [
            ("Yankees", "Dodgers", "Los Angeles Dodgers", "New York Yankees", 4, 3),
            ("Blue Jays", "Red Sox", "Boston Red Sox", "Toronto Blue Jays", 2, 5)
        ]

        for (team1, team2, homeFull, awayFull, homeScore, awayScore) in fakeGames {
            let candidates = [team1, team2, homeFull, awayFull].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let shouldInject = candidates.contains { normalizedTracked.contains($0) }
            guard shouldInject else { continue }

            let gameID = "\(awayFull)_vs_\(homeFull)"
            guard !promptedGames.contains(gameID) else { continue }

            let newGame = GameState(
                id: gameID,
                home: homeFull,
                away: awayFull,
                homeScore: homeScore,
                awayScore: awayScore,
                inning: Int.random(in: 5...9),
                isTopInning: Bool.random(),
                pitcher: "Test Pitcher",
                pitchCount: 80,
                batterBalls: Int.random(in: 0...3),
                batterStrikes: Int.random(in: 0...2),
                bases: [Bool.random(), Bool.random(), Bool.random()],
                batter: Batter(name: "Fake Batter", average: 0.286, hits: 45, atBats: 157),
                status: "In Progress",
                outs: 2
            )

            DispatchQueue.main.async {
                self.currentGames.append(newGame)
                self.promptedGames.insert(gameID)
                self.promptUserBeforeOverlay(game: newGame)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        spaceChangeTimer?.invalidate()
        detailTimers.values.forEach { $0.invalidate() }
        closeAllOverlays()
    }
}

class OverlayWindowDelegate: NSObject, NSWindowDelegate {
    weak var service: MLBStatsService?
    let gameID: String
    private var didCleanup = false

    init(service: MLBStatsService?, gameID: String) {
        self.service = service
        self.gameID = gameID
    }

    func windowWillClose(_ notification: Notification) {
        guard didCleanup == false else { return }
        didCleanup = true
        service?.cleanupOverlay(for: gameID)
    }

    deinit {
        print("deinitialized")
    }
}
