import AppKit
import SwiftUI

@MainActor
final class MLBStatsService: ObservableObject {
    @Published var currentGames: [GameState] = []
    @Published var selectedTeams: [String] = []

    @AppStorage("developerModeEnabled") private var developerModeEnabled = false

    private var overlayWindows: [String: NSWindow] = [:]
    private var overlayDelegates: [String: OverlayWindowDelegate] = [:]
    private var closingOverlayIDs: Set<String> = []
    private var promptedGames: Set<String> = []
    private var lastPromptDate = ""
    private var pollTask: Task<Void, Never>?
    private var detailTasks: [String: Task<Void, Never>] = [:]

    func startTracking(teams: [String]) {
        selectedTeams = teams
        closeAllOverlays()
        pollTask?.cancel()
        detailTasks.values.forEach { $0.cancel() }
        detailTasks.removeAll()
        currentGames.removeAll()
        promptedGames.removeAll()

        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.pollOnce()
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }

    private func pollOnce() async {
        resetPromptedGamesIfNewDay()
        guard !selectedTeams.isEmpty else { return }

        let today = MLBResponseParser.scheduleDate()
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(today)&hydrate=linescore") else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let games = try MLBResponseParser.liveGames(in: data, trackedTeams: selectedTeams)
            applySchedule(games)
        } catch {
            injectFakeGameIfNeeded(trackedTeams: selectedTeams)
        }
    }

    private func applySchedule(_ games: [TrackedGame]) {
        var liveIDs = Set<String>()
        for game in games {
            liveIDs.insert(game.id)
            if let index = currentGames.firstIndex(where: { $0.id == game.id }) {
                currentGames[index] = currentGames[index].updatingSchedule(from: game)
            } else {
                let state = game.initialState()
                currentGames.append(state)
                if !promptedGames.contains(game.id) {
                    promptedGames.insert(game.id)
                    promptUserBeforeOverlay(game: state)
                }
            }
            startDetailPolling(gamePk: game.gamePk, gameID: game.id)
        }

        for game in currentGames where !liveIDs.contains(game.id) {
            detailTasks[game.id]?.cancel()
            detailTasks[game.id] = nil
            closeOverlay(for: game.id)
        }
        currentGames.removeAll { !liveIDs.contains($0.id) }
        injectFakeGameIfNeeded(trackedTeams: selectedTeams)
    }

    private func startDetailPolling(gamePk: Int, gameID: String) {
        guard detailTasks[gameID] == nil else { return }
        detailTasks[gameID] = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.fetchGameDetails(gamePk: gamePk, gameID: gameID)
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    private func fetchGameDetails(gamePk: Int, gameID: String) async {
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1.1/game/\(gamePk)/feed/live") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let details = try MLBResponseParser.liveDetails(in: data)
            guard let index = currentGames.firstIndex(where: { $0.id == gameID }) else { return }
            currentGames[index] = currentGames[index].applying(details)
        } catch {
            return
        }
    }

    private func resetPromptedGamesIfNewDay() {
        let today = MLBResponseParser.scheduleDate()
        if today != lastPromptDate {
            promptedGames.removeAll()
            lastPromptDate = today
        }
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
        overlay.isOpaque = true
        overlay.backgroundColor = .windowBackgroundColor

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
        let delegate = OverlayWindowDelegate { [weak self] in
            self?.cleanupOverlay(for: game.id)
        }
        overlay.delegate = delegate
        overlay.orderFront(nil)
        overlayWindows[game.id] = overlay
        overlayDelegates[game.id] = delegate
    }

    func closeAllOverlays() {
        for (id, window) in overlayWindows {
            closingOverlayIDs.insert(id)
            window.performClose(nil)
            detailTasks[id]?.cancel()
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
        detailTasks[gameID]?.cancel()
        detailTasks.removeValue(forKey: gameID)
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
        if alert.runModal() == .alertFirstButtonReturn {
            showOverlay(for: game)
        }
    }

    private func injectFakeGameIfNeeded(trackedTeams: [String]) {
        #if DEBUG
        guard developerModeEnabled, currentGames.isEmpty, !trackedTeams.isEmpty else { return }

        let normalizedTracked = Set(trackedTeams.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        let fakeGames = [
            ("Yankees", "Dodgers", "Los Angeles Dodgers", "New York Yankees", 4, 3),
            ("Blue Jays", "Red Sox", "Boston Red Sox", "Toronto Blue Jays", 2, 5)
        ]

        for (team1, team2, homeFull, awayFull, homeScore, awayScore) in fakeGames {
            let candidates = [team1, team2, homeFull, awayFull].map { $0.lowercased() }
            guard candidates.contains(where: { normalizedTracked.contains($0) }) else { continue }

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
            currentGames.append(newGame)
            promptedGames.insert(gameID)
            promptUserBeforeOverlay(game: newGame)
        }
        #endif
    }
}

final class OverlayWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: @MainActor () -> Void
    private var didCleanup = false

    init(onClose: @escaping @MainActor () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        guard !didCleanup else { return }
        didCleanup = true
        let close = onClose
        Task { @MainActor in
            close()
        }
    }
}
