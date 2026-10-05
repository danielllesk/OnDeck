import type { ServerResponse } from "node:http"

const listeners = new Map<string, Set<ServerResponse>>()

export function subscribe(deviceId: string, response: ServerResponse): void {
  response.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  })
  response.write(": connected\n\n")
  const set = listeners.get(deviceId) ?? new Set<ServerResponse>()
  set.add(response)
  listeners.set(deviceId, set)
  response.on("close", () => {
    set.delete(response)
    if (set.size === 0) listeners.delete(deviceId)
  })
}

export function publish(deviceId: string, event: unknown): void {
  const set = listeners.get(deviceId)
  if (!set) return
  const payload = `data: ${JSON.stringify(event)}\n\n`
  for (const response of set) response.write(payload)
}
