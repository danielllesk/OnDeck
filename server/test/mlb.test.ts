import assert from "node:assert/strict"
import test from "node:test"
import { mlbDate, parseSchedule } from "../src/mlb.ts"

const payload = {
  dates: [
    {
      games: [
        {
          gamePk: 813071,
          officialDate: "2025-10-01",
          status: { detailedState: "Final" },
          teams: {
            away: { score: 3, team: { id: 145, name: "Chicago White Sox" } },
            home: { score: 5, team: { id: 114, name: "Cleveland Guardians" } },
          },
          linescore: { currentInning: 9, inningState: "Bottom" },
          lineups: {
            awayPlayers: numbered("Sox"),
            homePlayers: numbered("Guardians"),
          },
        },
      ],
    },
  ],
}

test("schedule parser keeps scores, inning, and the first nine", () => {
  const [game] = parseSchedule(payload, "2025-10-01")
  assert.equal(game.gamePk, 813071)
  assert.equal(game.awayScore, 3)
  assert.equal(game.homeScore, 5)
  assert.equal(game.inningState, "Bottom")
  assert.equal(game.homeLineup.length, 9)
  assert.equal(game.homeLineup[0].name, "Guardians 1")
  assert.equal(game.homeLineup[0].position, "CF")
})

test("mlb date is the New York calendar day", () => {
  const late = new Date("2026-10-06T02:30:00Z")
  assert.equal(mlbDate(late), "2026-10-05")
})

function numbered(prefix: string) {
  return Array.from({ length: 10 }, (_, index) => ({
    id: index + 1,
    fullName: `${prefix} ${index + 1}`,
    primaryPosition: { abbreviation: "CF" },
  }))
}
