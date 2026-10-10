import type pg from "pg"
import { diffGame, type GameChange, type GameSnapshot, type LineupPlayer } from "./diff"

export async function applySnapshots(pool: pg.Pool, snapshots: GameSnapshot[]): Promise<GameChange[]> {
  const changes: GameChange[] = []
  for (const snapshot of snapshots) {
    const previous = await loadSnapshot(pool, snapshot.gamePk)
    changes.push(...diffGame(previous, snapshot))
    await upsertSnapshot(pool, snapshot)
  }
  return changes
}

async function loadSnapshot(pool: pg.Pool, gamePk: number): Promise<GameSnapshot | null> {
  const game = await pool.query<{
    game_pk: number
    game_date: Date
    detailed_state: string
    home_team_id: number
    away_team_id: number
    home_name: string
    away_name: string
    home_score: number
    away_score: number
    inning: number | null
    inning_state: string | null
  }>(`select * from games where game_pk = $1`, [gamePk])
  const row = game.rows[0]
  if (!row) return null

  const lineups = await pool.query<{
    side: "home" | "away"
    batting_order: number
    player_id: number
    player_name: string
    position: string
  }>(
    `select side, batting_order, player_id, player_name, position
     from lineups where game_pk = $1 order by side, batting_order`,
    [gamePk],
  )

  const homeLineup: LineupPlayer[] = []
  const awayLineup: LineupPlayer[] = []
  for (const player of lineups.rows) {
    const entry = {
      id: player.player_id,
      name: player.player_name,
      position: player.position,
      order: player.batting_order,
    }
    if (player.side === "home") homeLineup.push(entry)
    else awayLineup.push(entry)
  }

  return {
    gamePk: row.game_pk,
    gameDate: dateOnly(row.game_date),
    detailedState: row.detailed_state,
    homeTeamId: row.home_team_id,
    awayTeamId: row.away_team_id,
    homeName: row.home_name,
    awayName: row.away_name,
    homeScore: row.home_score,
    awayScore: row.away_score,
    inning: row.inning,
    inningState: row.inning_state,
    homeLineup,
    awayLineup,
  }
}

function dateOnly(value: Date | string): string {
  if (value instanceof Date) return value.toISOString().slice(0, 10)
  return value.slice(0, 10)
}

async function upsertSnapshot(pool: pg.Pool, snapshot: GameSnapshot): Promise<void> {
  await pool.query(
    `insert into games (
       game_pk, game_date, detailed_state, home_team_id, away_team_id,
       home_name, away_name, home_score, away_score, inning, inning_state, updated_at
     ) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now())
     on conflict (game_pk) do update set
       detailed_state = excluded.detailed_state,
       home_score = excluded.home_score,
       away_score = excluded.away_score,
       inning = excluded.inning,
       inning_state = excluded.inning_state,
       updated_at = now()`,
    [
      snapshot.gamePk,
      snapshot.gameDate,
      snapshot.detailedState,
      snapshot.homeTeamId,
      snapshot.awayTeamId,
      snapshot.homeName,
      snapshot.awayName,
      snapshot.homeScore,
      snapshot.awayScore,
      snapshot.inning,
      snapshot.inningState,
    ],
  )

  await pool.query(`delete from lineups where game_pk = $1`, [snapshot.gamePk])
  for (const side of ["home", "away"] as const) {
    const players = side === "home" ? snapshot.homeLineup : snapshot.awayLineup
    for (const player of players) {
      await pool.query(
        `insert into lineups (game_pk, side, batting_order, player_id, player_name, position)
         values ($1, $2, $3, $4, $5, $6)`,
        [snapshot.gamePk, side, player.order, player.id, player.name, player.position],
      )
    }
  }
}
