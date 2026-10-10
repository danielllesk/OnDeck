import { readFile } from "node:fs/promises"
import pg from "pg"

const { Pool } = pg

export function createPool(connectionString = process.env.DATABASE_URL): pg.Pool {
  if (!connectionString) {
    throw new Error("DATABASE_URL is required")
  }
  return new Pool({ connectionString })
}

export async function waitForDatabase(pool: pg.Pool): Promise<void> {
  let lastError: unknown
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    try {
      await pool.query("select 1")
      return
    } catch (error) {
      lastError = error
      await new Promise((resolve) => setTimeout(resolve, 1000))
    }
  }
  throw lastError
}

export async function migrate(pool: pg.Pool): Promise<void> {
  const sql = await readFile(new URL("../migrations/001_init.sql", import.meta.url), "utf8")
  await pool.query(sql)
}
