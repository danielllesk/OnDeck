import Foundation

struct TrackedGame {
    let gamePk: Int
    let id: String
    let home: String
    let away: String
    let homeScore: Int
    let awayScore: Int
    let inning: Int
    let isTopInning: Bool
    let detailedState: String

    func initialState() -> GameState {
        GameState(
            id: id,
            home: home,
            away: away,
            homeScore: homeScore,
            awayScore: awayScore,
            inning: inning,
            isTopInning: isTopInning,
            pitcher: "Loading...",
            pitchCount: 0,
            batterBalls: 0,
            batterStrikes: 0,
            bases: [false, false, false],
            batter: nil,
            status: detailedState,
            outs: 0
        )
    }
}

struct LiveDetails {
    let pitcher: String
    let pitchCount: Int
    let batter: Batter
    let balls: Int
    let strikes: Int
    let outs: Int
    let inning: Int
    let isTopInning: Bool
    let bases: [Bool]
}

enum MLBResponseParser {
    static func scheduleDate(from date: Date = Date(), timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func isLive(detailedState: String) -> Bool {
        detailedState.contains("In Progress")
            || detailedState.contains("Delayed")
            || detailedState.contains("Warmup")
    }

    static func matchesTrackedTeam(_ teamName: String, trackedTeams: [String]) -> Bool {
        let name = teamName.lowercased()
        return trackedTeams.contains { raw in
            let token = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !token.isEmpty && name.contains(token)
        }
    }

    static func liveGames(in data: Data, trackedTeams: [String]) throws -> [TrackedGame] {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any] else { return [] }
        let dates = root["dates"] as? [[String: Any]] ?? []
        let games = dates.first?["games"] as? [[String: Any]] ?? []

        return games.compactMap { game in
            guard
                let gamePk = JSONValue.int(game["gamePk"]),
                let teams = game["teams"] as? [String: Any],
                let home = (teams["home"] as? [String: Any])?["team"] as? [String: Any],
                let away = (teams["away"] as? [String: Any])?["team"] as? [String: Any],
                let homeName = home["name"] as? String,
                let awayName = away["name"] as? String,
                let status = game["status"] as? [String: Any],
                let detailedState = status["detailedState"] as? String,
                isLive(detailedState: detailedState),
                matchesTrackedTeam(homeName, trackedTeams: trackedTeams)
                    || matchesTrackedTeam(awayName, trackedTeams: trackedTeams)
            else { return nil }

            let linescore = game["linescore"] as? [String: Any]
            return TrackedGame(
                gamePk: gamePk,
                id: String(gamePk),
                home: homeName,
                away: awayName,
                homeScore: JSONValue.int((teams["home"] as? [String: Any])?["score"]) ?? 0,
                awayScore: JSONValue.int((teams["away"] as? [String: Any])?["score"]) ?? 0,
                inning: JSONValue.int(linescore?["currentInning"]) ?? 1,
                isTopInning: JSONValue.bool(linescore?["isTopInning"]) ?? true,
                detailedState: detailedState
            )
        }
    }

    static func liveDetails(in data: Data) throws -> LiveDetails {
        let json = try JSONSerialization.jsonObject(with: data)
        guard
            let root = json as? [String: Any],
            let liveData = root["liveData"] as? [String: Any],
            let plays = liveData["plays"] as? [String: Any],
            let currentPlay = plays["currentPlay"] as? [String: Any],
            let matchup = currentPlay["matchup"] as? [String: Any],
            let linescore = liveData["linescore"] as? [String: Any]
        else {
            throw ParserError.missingLiveData
        }

        let pitcherData = matchup["pitcher"] as? [String: Any]
        let pitcherName = pitcherData?["fullName"] as? String ?? "Unknown Pitcher"
        let pitcherID = JSONValue.int(pitcherData?["id"]) ?? 0

        let batterData = matchup["batter"] as? [String: Any]
        let batterName = batterData?["fullName"] as? String ?? "Unknown Batter"
        let batterID = JSONValue.int(batterData?["id"]) ?? 0

        let boxscore = liveData["boxscore"] as? [String: Any]
        let teams = boxscore?["teams"] as? [String: Any]
        let inningState = linescore["inningState"] as? String ?? "Top"
        let isTopInning = inningState.lowercased().contains("top")
        let battingTeam = isTopInning ? "away" : "home"
        let pitchingTeam = isTopInning ? "home" : "away"

        var pitchCount = 0
        if let pitching = statGroup(teams: teams, side: pitchingTeam, playerID: pitcherID, listKey: "pitchers", group: "pitching") {
            pitchCount = JSONValue.int(pitching["numberOfPitches"]) ?? 0
        }

        var seasonAvg = 0.0
        var hits = 0
        var atBats = 0
        if let batting = statGroup(teams: teams, side: battingTeam, playerID: batterID, listKey: "batters", group: "batting") {
            hits = JSONValue.int(batting["hits"]) ?? 0
            atBats = JSONValue.int(batting["atBats"]) ?? 0
            if let avg = batting["avg"] as? String {
                seasonAvg = Double(avg) ?? 0.0
            }
        }
        if seasonAvg == 0.0,
           let season = seasonBatting(teams: teams, side: battingTeam, playerID: batterID),
           let avg = season["avg"] as? String {
            seasonAvg = Double(avg) ?? 0.0
        }

        let count = (currentPlay["count"] as? [String: Any]) ?? [:]
        var bases = [false, false, false]
        if let offense = linescore["offense"] as? [String: Any] {
            bases[0] = (offense["first"] as? [String: Any])?["id"] != nil
            bases[1] = (offense["second"] as? [String: Any])?["id"] != nil
            bases[2] = (offense["third"] as? [String: Any])?["id"] != nil
        }

        return LiveDetails(
            pitcher: pitcherName,
            pitchCount: pitchCount,
            batter: Batter(name: batterName, average: seasonAvg, hits: hits, atBats: atBats),
            balls: JSONValue.int(count["balls"]) ?? 0,
            strikes: JSONValue.int(count["strikes"]) ?? 0,
            outs: JSONValue.int(linescore["outs"]) ?? 0,
            inning: JSONValue.int(linescore["currentInning"]) ?? 1,
            isTopInning: isTopInning,
            bases: bases
        )
    }

    enum ParserError: Error {
        case missingLiveData
    }

    private static func statGroup(
        teams: [String: Any]?,
        side: String,
        playerID: Int,
        listKey: String,
        group: String
    ) -> [String: Any]? {
        guard
            playerID != 0,
            let sideData = teams?[side] as? [String: Any],
            let listed = sideData[listKey] as? [Any],
            listed.contains(where: { JSONValue.int($0) == playerID }),
            let player = player(sideData, id: playerID),
            let stats = player["stats"] as? [String: Any]
        else { return nil }
        return stats[group] as? [String: Any]
    }

    private static func seasonBatting(teams: [String: Any]?, side: String, playerID: Int) -> [String: Any]? {
        guard
            playerID != 0,
            let sideData = teams?[side] as? [String: Any],
            let player = player(sideData, id: playerID),
            let seasonStats = player["seasonStats"] as? [String: Any]
        else { return nil }
        return seasonStats["batting"] as? [String: Any]
    }

    private static func player(_ sideData: [String: Any], id: Int) -> [String: Any]? {
        let players = sideData["players"] as? [String: Any]
        return players?["ID\(id)"] as? [String: Any]
    }
}

enum JSONValue {
    static func int(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber else { return nil }
        if CFGetTypeID(number) == CFBooleanGetTypeID() { return nil }
        return number.intValue
    }

    static func bool(_ value: Any?) -> Bool? {
        guard let number = value as? NSNumber else { return nil }
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return number.boolValue
        }
        return nil
    }
}
