import assert from "node:assert/strict"
import test from "node:test"
import { diffGame, gameInvolvesTeam, type GameSnapshot, type LineupPlayer } from "../src/diff.ts"

const nine = (prefix: string): LineupPlayer[] =>
  Array.from({ length: 9 }, (_, index) => ({
    id: index + 1,
    name: `${prefix} ${index + 1}`,
    position: "CF",
    order: index + 1,
  }))

function game(overrides: Partial<GameSnapshot> = {}): GameSnapshot {
  return {
    gamePk: 746201,
    gameDate: "2026-10-05",
    detailedState: "In Progress",
    homeTeamId: 111,
    awayTeamId: 141,
    homeName: "Boston Red Sox",
    awayName: "Toronto Blue Jays",
    homeScore: 0,
    awayScore: 0,
    inning: 1,
    inningState: "Top",
    homeLineup: [],
    awayLineup: [],
    ...overrides,
  }
}

test("first snapshot announces a posted lineup and not a 0-0 score", () => {
  const changes = diffGame(null, game({ awayLineup: nine("Jays"), homeLineup: nine("Sox") }))
  assert.equal(changes.filter((change) => change.kind === "score").length, 0)
  assert.equal(changes.filter((change) => change.kind === "lineup").length, 2)
  assert.match(changes[0].title, /Blue Jays lineup/)
})

test("score changes notify once per new score", () => {
  const previous = game({ awayScore: 1, homeScore: 0 })
  const next = game({ awayScore: 2, homeScore: 0, inning: 4, inningState: "Top" })
  const changes = diffGame(previous, next)
  assert.deepEqual(
    changes.map((change) => change.kind),
    ["score"],
  )
  assert.equal(changes[0].title, "Toronto Blue Jays 2, Boston Red Sox 0")
  assert.equal(changes[0].body, "Top 4")
  assert.equal(diffGame(next, next).length, 0)
})

test("an unchanged lineup is quiet and a new batting order is not", () => {
  const lineup = nine("Jays")
  const previous = game({ awayLineup: lineup })
  assert.equal(diffGame(previous, game({ awayLineup: lineup })).length, 0)
  const flipped = [...lineup].reverse().map((player, index) => ({ ...player, order: index + 1 }))
  const changes = diffGame(previous, game({ awayLineup: flipped }))
  assert.equal(changes.length, 1)
  assert.equal(changes[0].kind, "lineup")
})

test("short lineups wait until nine names are posted", () => {
  const changes = diffGame(null, game({ awayLineup: nine("Jays").slice(0, 3) }))
  assert.equal(changes.length, 0)
})

test("team matching uses the nickname the app stores", () => {
  assert.equal(gameInvolvesTeam("Toronto Blue Jays", "Boston Red Sox", "Blue Jays"), true)
  assert.equal(gameInvolvesTeam("Toronto Blue Jays", "Boston Red Sox", "Yankees"), false)
  assert.equal(gameInvolvesTeam("Toronto Blue Jays", "Boston Red Sox", "  "), false)
})
