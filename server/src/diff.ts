export type LineupPlayer = {
  id: number
  name: string
  position: string
  order: number
}

export type GameSnapshot = {
  gamePk: number
  gameDate: string
  detailedState: string
  homeTeamId: number
  awayTeamId: number
  homeName: string
  awayName: string
  homeScore: number
  awayScore: number
  inning: number | null
  inningState: string | null
  homeLineup: LineupPlayer[]
  awayLineup: LineupPlayer[]
}

export type GameChange = {
  kind: "score" | "lineup"
  gamePk: number
  homeName: string
  awayName: string
  title: string
  body: string
  dedupe: string
}

const STARTING_NINE = 9

export function gameInvolvesTeam(home: string, away: string, tracked: string): boolean {
  const token = tracked.trim().toLowerCase()
  if (!token) return false
  return home.toLowerCase().includes(token) || away.toLowerCase().includes(token)
}

export function diffGame(prev: GameSnapshot | null, next: GameSnapshot): GameChange[] {
  const changes: GameChange[] = []
  if (prev && (prev.homeScore !== next.homeScore || prev.awayScore !== next.awayScore)) {
    const inning = next.inningState && next.inning ? `${next.inningState} ${next.inning}` : next.detailedState
    changes.push({
      kind: "score",
      gamePk: next.gamePk,
      homeName: next.homeName,
      awayName: next.awayName,
      title: `${next.awayName} ${next.awayScore}, ${next.homeName} ${next.homeScore}`,
      body: inning,
      dedupe: `score:${next.gamePk}:${next.awayScore}-${next.homeScore}`,
    })
  }

  changes.push(...lineupChange(prev?.awayLineup ?? [], next.awayLineup, next, next.awayName, "away"))
  changes.push(...lineupChange(prev?.homeLineup ?? [], next.homeLineup, next, next.homeName, "home"))
  return changes
}

function lineupChange(
  previous: LineupPlayer[],
  nextPlayers: LineupPlayer[],
  game: GameSnapshot,
  teamName: string,
  side: "home" | "away",
): GameChange[] {
  if (nextPlayers.length < STARTING_NINE) return []
  const nextIds = nextPlayers.map((player) => player.id).join("-")
  const prevIds = previous.map((player) => player.id).join("-")
  if (previous.length >= STARTING_NINE && prevIds === nextIds) return []

  const body = nextPlayers
    .map((player) => `${player.order}. ${player.name}${player.position ? ` ${player.position}` : ""}`)
    .join(", ")
    .slice(0, 180)

  return [{
    kind: "lineup",
    gamePk: game.gamePk,
    homeName: game.homeName,
    awayName: game.awayName,
    title: `${teamName} lineup`,
    body,
    dedupe: `lineup:${game.gamePk}:${side}:${nextIds}`,
  }]
}
