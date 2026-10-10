import type { GameSnapshot, LineupPlayer } from "./diff"

const MLB_BASE = "https://statsapi.mlb.com/api/v1/schedule"

export function mlbDate(now = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/New_York",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now)
}

export async function fetchSchedule(date = mlbDate()): Promise<GameSnapshot[]> {
  const url = new URL(MLB_BASE)
  url.searchParams.set("sportId", "1")
  url.searchParams.set("date", date)
  url.searchParams.set("hydrate", "linescore,lineups,team")
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`MLB schedule ${response.status}`)
  }
  return parseSchedule(await response.json(), date)
}

export function parseSchedule(payload: unknown, fallbackDate: string): GameSnapshot[] {
  const root = record(payload)
  const dates = Array.isArray(root?.dates) ? root.dates : []
  const games: GameSnapshot[] = []
  for (const dateEntry of dates) {
    const dateRecord = record(dateEntry)
    const listed = Array.isArray(dateRecord?.games) ? dateRecord.games : []
    for (const game of listed) {
      const parsed = parseGame(game, fallbackDate)
      if (parsed) games.push(parsed)
    }
  }
  return games
}

function parseGame(value: unknown, fallbackDate: string): GameSnapshot | null {
  const game = record(value)
  if (!game || typeof game.gamePk !== "number") return null
  const teams = record(game.teams)
  const home = side(teams?.home)
  const away = side(teams?.away)
  if (!home || !away) return null

  const linescore = record(game.linescore)
  const lineups = record(game.lineups)
  const status = record(game.status)

  return {
    gamePk: game.gamePk,
    gameDate: typeof game.officialDate === "string" ? game.officialDate : fallbackDate,
    detailedState: typeof status?.detailedState === "string" ? status.detailedState : "Scheduled",
    homeTeamId: home.id,
    awayTeamId: away.id,
    homeName: home.name,
    awayName: away.name,
    homeScore: home.score,
    awayScore: away.score,
    inning: typeof linescore?.currentInning === "number" ? linescore.currentInning : null,
    inningState: typeof linescore?.inningState === "string" ? linescore.inningState : null,
    homeLineup: parseLineup(lineups?.homePlayers),
    awayLineup: parseLineup(lineups?.awayPlayers),
  }
}

function side(value: unknown): { id: number; name: string; score: number } | null {
  const entry = record(value)
  const team = record(entry?.team)
  if (!team || typeof team.id !== "number" || typeof team.name !== "string") return null
  return {
    id: team.id,
    name: team.name,
    score: typeof entry?.score === "number" ? entry.score : 0,
  }
}

function parseLineup(value: unknown): LineupPlayer[] {
  if (!Array.isArray(value)) return []
  const players: LineupPlayer[] = []
  for (const entry of value.slice(0, 9)) {
    const player = record(entry)
    if (!player || typeof player.id !== "number" || typeof player.fullName !== "string") continue
    const position = record(player.primaryPosition)
    players.push({
      id: player.id,
      name: player.fullName,
      position: typeof position?.abbreviation === "string" ? position.abbreviation : "",
      order: players.length + 1,
    })
  }
  return players
}

function record(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null
  return value as Record<string, unknown>
}
