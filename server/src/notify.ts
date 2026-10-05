import type pg from "pg"
import { sendApns } from "./apns"
import type { GameChange } from "./diff"
import { publish } from "./sse"

export async function fanout(pool: pg.Pool, change: GameChange): Promise<number> {
  const devices = await pool.query<{ id: string; apns_token: string | null }>(
    `select distinct d.id, d.apns_token
     from devices d
     join device_teams t on t.device_id = d.id
     where strpos(lower($1), lower(t.team_name)) > 0
        or strpos(lower($2), lower(t.team_name)) > 0`,
    [change.homeName, change.awayName],
  )

  let delivered = 0
  for (const device of devices.rows) {
    const inserted = await pool.query(
      `insert into notifications (device_id, kind, title, body, dedupe_key)
       values ($1, $2, $3, $4, $5)
       on conflict (device_id, dedupe_key) do nothing
       returning id`,
      [device.id, change.kind, change.title, change.body, change.dedupe],
    )
    if ((inserted.rowCount ?? 0) === 0) continue
    delivered += 1
    const event = { kind: change.kind, title: change.title, body: change.body, gamePk: change.gamePk }
    publish(device.id, event)
    if (device.apns_token) {
      const sent = await sendApns(device.apns_token, change.title, change.body)
      if (sent) {
        await pool.query(`update notifications set apns_sent_at = now() where id = $1`, [inserted.rows[0].id])
      }
    }
  }
  return delivered
}
