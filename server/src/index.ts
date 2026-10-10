import { hostname } from "node:os"
import { createPool, migrate, waitForDatabase } from "./db"
import { createApp } from "./http"
import { enqueueScheduleIfIdle } from "./queue"
import { runWorker } from "./worker"

const port = Number(process.env.PORT ?? 8787)
const workerId = `${hostname()}:${process.pid}`
let stopped = false

const pool = createPool()
await waitForDatabase(pool)
await migrate(pool)
await enqueueScheduleIfIdle(pool)

const server = createApp(pool)
server.listen(port, () => {
  console.log(`ondeck listening on ${port}`)
})

const scheduler = setInterval(() => {
  void enqueueScheduleIfIdle(pool).catch((error: unknown) => {
    console.error("scheduler", error)
  })
}, 20_000)

void runWorker(pool, workerId, () => stopped).catch((error: unknown) => {
  console.error("worker", error)
  process.exitCode = 1
})

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    stopped = true
    clearInterval(scheduler)
    server.close()
    void pool.end()
  })
}
