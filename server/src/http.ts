import { createServer, type IncomingMessage, type ServerResponse } from "node:http"
import type pg from "pg"
import { subscribe } from "./sse"

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

export function createApp(pool: pg.Pool) {
  return createServer(async (request, response) => {
    try {
      await route(pool, request, response)
    } catch (error) {
      const message = error instanceof Error ? error.message : "error"
      sendJson(response, message === "body too large" ? 413 : 400, { error: message })
    }
  })
}

async function route(pool: pg.Pool, request: IncomingMessage, response: ServerResponse): Promise<void> {
  const url = new URL(request.url ?? "/", "http://localhost")
  const path = url.pathname

  if (request.method === "GET" && path === "/health") {
    sendJson(response, 200, { ok: true })
    return
  }

  if (request.method === "GET" && path === "/v1/stats/weekly") {
    const result = await pool.query<{ count: string }>(
      `select count(*)::text as count from devices where last_seen_at > now() - interval '7 days'`,
    )
    sendJson(response, 200, { weeklyActiveDevices: Number(result.rows[0]?.count ?? 0) })
    return
  }

  const stream = path.match(/^\/v1\/devices\/([^/]+)\/stream$/)
  if (request.method === "GET" && stream) {
    const deviceId = stream[1]
    if (!UUID.test(deviceId)) {
      sendJson(response, 400, { error: "device id must be a uuid" })
      return
    }
    subscribe(deviceId, response)
    return
  }

  if (request.method === "POST" && path === "/v1/devices") {
    const body = await readJson(request)
    const id = stringField(body, "id")
    const teams = Array.isArray(body.teams) ? body.teams.filter((team): team is string => typeof team === "string") : []
    const apnsToken = typeof body.apnsToken === "string" ? body.apnsToken : null
    if (!id || !UUID.test(id)) {
      sendJson(response, 400, { error: "id must be a uuid" })
      return
    }
    const cleanTeams = [...new Set(teams.map((team) => team.trim()).filter(Boolean))].slice(0, 30)
    await pool.query(
      `insert into devices (id, apns_token, last_seen_at)
       values ($1, $2, now())
       on conflict (id) do update set
         apns_token = coalesce(excluded.apns_token, devices.apns_token),
         last_seen_at = now()`,
      [id, apnsToken],
    )
    await pool.query(`delete from device_teams where device_id = $1`, [id])
    for (const team of cleanTeams) {
      await pool.query(
        `insert into device_teams (device_id, team_name) values ($1, $2) on conflict do nothing`,
        [id, team],
      )
    }
    sendJson(response, 200, { id, teams: cleanTeams })
    return
  }

  sendJson(response, 404, { error: "not found" })
}

function stringField(body: Record<string, unknown>, key: string): string | null {
  return typeof body[key] === "string" ? body[key] : null
}

async function readJson(request: IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = []
  let size = 0
  for await (const chunk of request) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)
    size += buffer.length
    if (size > 65_536) throw new Error("body too large")
    chunks.push(buffer)
  }
  if (size === 0) return {}
  const parsed: unknown = JSON.parse(Buffer.concat(chunks).toString("utf8"))
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("expected a json object")
  }
  return parsed as Record<string, unknown>
}

function sendJson(response: ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body)
  response.writeHead(status, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(payload),
  })
  response.end(payload)
}
