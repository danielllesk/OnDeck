import type pg from "pg"

export type Job = {
  id: string
  kind: string
  payload: Record<string, unknown>
  attempts: number
}

export async function enqueue(
  pool: pg.Pool,
  kind: string,
  payload: Record<string, unknown> = {},
  runAt = new Date(),
): Promise<void> {
  await pool.query(
    `insert into jobs (kind, payload, run_at) values ($1, $2::jsonb, $3)`,
    [kind, JSON.stringify(payload), runAt],
  )
}

export async function enqueueScheduleIfIdle(pool: pg.Pool): Promise<void> {
  const pending = await pool.query(
    `select 1 from jobs where kind = 'poll_schedule' and done_at is null limit 1`,
  )
  if ((pending.rowCount ?? 0) > 0) return
  await enqueue(pool, "poll_schedule")
}

export async function claimJob(pool: pg.Pool, workerId: string): Promise<Job | null> {
  const result = await pool.query<{
    id: string
    kind: string
    payload: Record<string, unknown>
    attempts: number
  }>(
    `with next_job as (
       select id
       from jobs
       where done_at is null
         and run_at <= now()
         and (locked_at is null or locked_at < now() - interval '2 minutes')
       order by id
       for update skip locked
       limit 1
     )
     update jobs
     set locked_at = now(),
         locked_by = $1,
         attempts = jobs.attempts + 1
     from next_job
     where jobs.id = next_job.id
     returning jobs.id, jobs.kind, jobs.payload, jobs.attempts`,
    [workerId],
  )
  return result.rows[0] ?? null
}

export async function completeJob(pool: pg.Pool, id: string): Promise<void> {
  await pool.query(
    `update jobs set done_at = now(), locked_at = null, last_error = null where id = $1`,
    [id],
  )
}

export async function failJob(pool: pg.Pool, id: string, error: unknown): Promise<void> {
  const message = error instanceof Error ? error.message : String(error)
  await pool.query(
    `update jobs
     set locked_at = null,
         locked_by = null,
         last_error = $2,
         run_at = now() + interval '15 seconds'
     where id = $1`,
    [id, message.slice(0, 500)],
  )
}
