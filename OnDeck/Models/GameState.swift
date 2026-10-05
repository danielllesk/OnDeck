import Foundation

struct Batter: Equatable {
    let name: String
    let average: Double
    let hits: Int
    let atBats: Int
}

struct GameState: Identifiable, Equatable {
    let id: String
    let home: String
    let away: String
    let homeScore: Int
    let awayScore: Int
    let inning: Int
    let isTopInning: Bool
    let pitcher: String
    let pitchCount: Int
    let batterBalls: Int
    let batterStrikes: Int
    let bases: [Bool]
    let batter: Batter?
    let status: String
    let outs: Int

    func updatingSchedule(from game: TrackedGame) -> GameState {
        GameState(
            id: id,
            home: game.home,
            away: game.away,
            homeScore: game.homeScore,
            awayScore: game.awayScore,
            inning: game.inning,
            isTopInning: game.isTopInning,
            pitcher: pitcher,
            pitchCount: pitchCount,
            batterBalls: batterBalls,
            batterStrikes: batterStrikes,
            bases: bases,
            batter: batter,
            status: game.detailedState,
            outs: outs
        )
    }

    func applying(_ details: LiveDetails) -> GameState {
        GameState(
            id: id,
            home: home,
            away: away,
            homeScore: homeScore,
            awayScore: awayScore,
            inning: details.inning,
            isTopInning: details.isTopInning,
            pitcher: details.pitcher,
            pitchCount: details.pitchCount,
            batterBalls: details.balls,
            batterStrikes: details.strikes,
            bases: details.bases,
            batter: details.batter,
            status: status,
            outs: details.outs
        )
    }
}
