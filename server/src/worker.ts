import type pg from "pg"
import { applySnapshots } from "./games"
import { fetchSchedule } from "./mlb"
import { fanout } from "./notify"
import { claimJob, completeJob, enqueue, failJob } from "./queue"
import type { GameChange } from "./diff"

export async function handleJob(pool: pg.Pool, kind: string, payload: Record<string, unknown>): Promise<void> {
  if (kind === "poll_schedule") {
    const snapshots = await fetchSchedule()
    const changes = await applySnapshots(pool, snapshots)
    for (const change of changes) {
      await enqueue(pool, "notify", changePayload(change))
    }
    return
  }

  if (kind === "notify") {
    await fanout(pool, changeFromPayload(payload))
    return
  }

  throw new Error(`unknown job ${kind}`)
}

export async function runWorker(pool: pg.Pool, workerId: string, stop: () => boolean): Promise<void> {
  while (!stop()) {
    const job = await claimJob(pool, workerId)
    if (!job) {
      await new Promise((resolve) => setTimeout(resolve, 1000))
      continue
    }
    try {
      await handleJob(pool, job.kind, job.payload)
      await completeJob(pool, job.id)
    } catch (error) {
      await failJob(pool, job.id, error)
    }
  }
}

function changePayload(change: GameChange): Record<string, unknown> {
  return { ...change }
}

function changeFromPayload(payload: Record<string, unknown>): GameChange {
  if (
    (payload.kind !== "score" && payload.kind !== "lineup")
    || typeof payload.gamePk !== "number"
    || typeof payload.homeName !== "string"
    || typeof payload.awayName !== "string"
    || typeof payload.title !== "string"
    || typeof payload.body !== "string"
    || typeof payload.dedupe !== "string"
  ) {
    throw new Error("notify payload is incomplete")
  }
  return {
    kind: payload.kind,
    gamePk: payload.gamePk,
    homeName: payload.homeName,
    awayName: payload.awayName,
    title: payload.title,
    body: payload.body,
    dedupe: payload.dedupe,
  }
}
