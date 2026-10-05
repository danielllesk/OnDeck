import XCTest
@testable import OnDeck

final class OnDeckTests: XCTestCase {
    func testScheduleParserKeepsOnlyLiveTrackedGames() throws {
        let data = Data(scheduleJSON.utf8)
        let games = try MLBResponseParser.liveGames(in: data, trackedTeams: ["Blue Jays"])

        XCTAssertEqual(games.map(\.id), ["746201"])
        XCTAssertEqual(games.first?.away, "Toronto Blue Jays")
        XCTAssertEqual(games.first?.homeScore, 2)
        XCTAssertEqual(games.first?.inning, 7)
        XCTAssertEqual(games.first?.isTopInning, false)
    }

    func testScheduleParserIgnoresFinalGames() throws {
        let data = Data(scheduleJSON.utf8)
        let games = try MLBResponseParser.liveGames(in: data, trackedTeams: ["Yankees"])
        XCTAssertTrue(games.isEmpty)
    }

    func testLiveDetailsReadBoxscoreStats() throws {
        let details = try MLBResponseParser.liveDetails(in: Data(liveFeedJSON.utf8))

        XCTAssertEqual(details.pitcher, "Chris Bassitt")
        XCTAssertEqual(details.pitchCount, 87)
        XCTAssertEqual(details.batter.name, "Aaron Judge")
        XCTAssertEqual(details.batter.hits, 2)
        XCTAssertEqual(details.batter.atBats, 3)
        XCTAssertEqual(details.batter.average, 0.311)
        XCTAssertEqual(details.balls, 2)
        XCTAssertEqual(details.strikes, 1)
        XCTAssertEqual(details.outs, 1)
        XCTAssertEqual(details.bases, [true, false, true])
        XCTAssertTrue(details.isTopInning)
    }

    func testLogoURLUsesTheTeamList() {
        XCTAssertEqual(
            logoURL(for: "Toronto Blue Jays"),
            "https://www.mlbstatic.com/team-logos/141.svg"
        )
        XCTAssertEqual(
            logoURL(for: "White Sox"),
            "https://www.mlbstatic.com/team-logos/145.svg"
        )
        XCTAssertEqual(
            logoURL(for: "Red Sox"),
            "https://www.mlbstatic.com/team-logos/111.svg"
        )
    }

    func testScheduleRefreshKeepsBatterDetails() {
        let game = TrackedGame(
            gamePk: 1,
            id: "1",
            home: "Boston Red Sox",
            away: "Toronto Blue Jays",
            homeScore: 1,
            awayScore: 3,
            inning: 4,
            isTopInning: true,
            detailedState: "In Progress"
        )
        let existing = game.initialState().applying(
            LiveDetails(
                pitcher: "Chris Bassitt",
                pitchCount: 40,
                batter: Batter(name: "Aaron Judge", average: 0.300, hits: 1, atBats: 2),
                balls: 1,
                strikes: 1,
                outs: 2,
                inning: 4,
                isTopInning: true,
                bases: [false, false, false]
            )
        )
        let updated = existing.updatingSchedule(from: TrackedGame(
            gamePk: 1,
            id: "1",
            home: "Boston Red Sox",
            away: "Toronto Blue Jays",
            homeScore: 1,
            awayScore: 4,
            inning: 4,
            isTopInning: true,
            detailedState: "In Progress"
        ))

        XCTAssertEqual(updated.awayScore, 4)
        XCTAssertEqual(updated.pitcher, "Chris Bassitt")
        XCTAssertEqual(updated.batter?.name, "Aaron Judge")
    }
}

private let scheduleJSON = """
{
  "dates": [
    {
      "games": [
        {
          "gamePk": 746201,
          "status": { "detailedState": "In Progress" },
          "teams": {
            "away": { "score": 4, "team": { "name": "Toronto Blue Jays" } },
            "home": { "score": 2, "team": { "name": "Boston Red Sox" } }
          },
          "linescore": { "currentInning": 7, "isTopInning": false }
        },
        {
          "gamePk": 746202,
          "status": { "detailedState": "Final" },
          "teams": {
            "away": { "score": 1, "team": { "name": "New York Yankees" } },
            "home": { "score": 6, "team": { "name": "Baltimore Orioles" } }
          }
        }
      ]
    }
  ]
}
"""

private let liveFeedJSON = """
{
  "liveData": {
    "plays": {
      "currentPlay": {
        "count": { "balls": 2, "strikes": 1 },
        "matchup": {
          "pitcher": { "id": 605135, "fullName": "Chris Bassitt" },
          "batter": { "id": 592450, "fullName": "Aaron Judge" }
        }
      }
    },
    "linescore": {
      "currentInning": 7,
      "inningState": "Top",
      "outs": 1,
      "offense": {
        "first": { "id": 1 },
        "third": { "id": 3 }
      }
    },
    "boxscore": {
      "teams": {
        "home": {
          "pitchers": [605135],
          "players": {
            "ID605135": {
              "stats": { "pitching": { "numberOfPitches": 87 } }
            }
          }
        },
        "away": {
          "batters": [592450],
          "players": {
            "ID592450": {
              "stats": { "batting": { "hits": 2, "atBats": 3, "avg": ".000" } },
              "seasonStats": { "batting": { "avg": ".311" } }
            }
          }
        }
      }
    }
  }
}
"""
