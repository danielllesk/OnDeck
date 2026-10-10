# OnDeck server

Postgres stores games, lineups, devices, and a job queue. One Node process schedules a poll, and a worker claims jobs with `FOR UPDATE SKIP LOCKED`.

`poll_schedule` reads today's MLB schedule (New York date), including scores and posted lineups. Score changes and new starting nines become `notify` jobs. Those jobs write one notification per subscribed device, push it to any app currently connected, and send an Apple push when APNs credentials are set.

## Run

```bash
cd server
docker compose up --build
```

Health check: `curl http://127.0.0.1:8787/health`

Weekly devices that have checked in: `curl http://127.0.0.1:8787/v1/stats/weekly`

The Mac app in a Debug build talks to `http://127.0.0.1:8787`. Point a Release build at a host with the `BackendBaseURL` Info.plist value, or set the `backendBaseURL` user default.

Subscribe a device by saving teams in the app, or:

```bash
curl -X POST http://127.0.0.1:8787/v1/devices \
  -H 'content-type: application/json' \
  -d '{"id":"11111111-1111-4111-8111-111111111111","teams":["Blue Jays"]}'
```
