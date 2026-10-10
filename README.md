# OnDeck — Live MLB Game Tracker for macOS

**OnDeck** is a macOS app that keeps baseball fans up to date with every pitch, hit, and run from the desktop. It floats live score overlays, shows real-time stats, and can push score and lineup alerts when a backend is running.

---

## DEMO

<a href="https://drive.google.com/file/d/1vumWW37yPY5pOiLYQaJXnf6N-Gq1QA3L/view?usp=sharing">
  <img src="OnDeckLogo(3).png" alt="Watch the Demo" width="500">
</a>

---

## Overview

Baseball is best in real time, but most apps bury the game behind browsers and ads. OnDeck brings it to you with lightweight scorebug overlays that refresh automatically.

You can:

- Select favorite teams to follow through the season
- Get notified when a tracked game goes live
- Float scorebug windows with inning, bases, count, outs, pitcher, pitch count, and batter info
- Track tonight’s hits/at-bats and season (or postseason) average
- Save preferences locally so selections persist across sessions
- Optionally connect to a small backend for score-change and lineup notifications (SSE + APNs)

---

## Architecture

```
┌─────────────────────┐         MLB Stats API
│  OnDeck (macOS)     │◄───────────────────────┐
│  • team picker      │                        │
│  • scorebug overlay │  poll schedule + feed  │
│  • local prefs      │                        │
└─────────┬───────────┘                        │
          │ register teams / SSE stream        │
          ▼                                    │
┌─────────────────────┐                        │
│  server/ (Node)     │────────────────────────┘
│  • Postgres         │  poll schedule + scores
│  • job queue         │
│  • notify worker    │──► in-app SSE + APNs
└─────────────────────┘
```

**Mac app** — polls the public [MLB Stats API](https://statsapi.mlb.com) for schedule and per-game `feed/live` details. Parsing lives in `MLBResponseParser` so the live scoreboard can be unit-tested without the UI.

**Server (optional)** — Postgres stores games, lineups, devices, and a job queue. A worker claims jobs with `FOR UPDATE SKIP LOCKED`, diffs scores/lineups, and notifies subscribed devices over SSE (and APNs when credentials are set).

---

## Scorebug overlay

Each floating overlay shows:

| Area | What’s shown |
|------|----------------|
| Header | Away/home names, logos, scores |
| Status | Inning (▲/▼), balls-strikes count |
| At bat | Batter name, average, tonight’s H-AB |
| Pitcher | Name and **pitch count** (`N pitches`, under the pitcher name) |
| Bases / outs | Diamond occupancy and three-out dots |

Overlays use `NSWindow`, stay above other windows without stealing focus, can be dragged anywhere, and close when the game ends.

---

## How live updates work

### In the Mac app

1. **Save & Start Tracking** stores selected teams and begins schedule polling.
2. Every ~30 seconds the app checks MLB’s schedule for live games involving those teams.
3. When a game goes live, you’re prompted to open a floating score overlay.
4. While an overlay is open, the app polls that game’s `feed/live` endpoint for batter, pitcher, pitch count, bases, count, outs, inning, and scores.
5. When the game ends, the overlay closes and tracking for that game stops.

### With the backend

1. Saving teams also registers the device (`POST /v1/devices`) and opens an SSE stream.
2. The server polls today’s MLB schedule (America/New_York date).
3. Score changes and newly posted starting nines enqueue `notify` jobs.
4. The worker delivers one notification per subscribed device over the live stream (and APNs when configured).

Debug builds talk to `http://127.0.0.1:8787` by default. Release builds use the `BackendBaseURL` Info.plist value, or the `backendBaseURL` user default.

---

## Run locally

### Mac app

Open `OnDeck.xcodeproj` in Xcode and run the **OnDeck** scheme (macOS 13+).

### Server

```bash
cd server
docker compose up --build
```

- Health: `curl http://127.0.0.1:8787/health`
- Weekly active devices: `curl http://127.0.0.1:8787/v1/stats/weekly`
- Manual subscribe:

```bash
curl -X POST http://127.0.0.1:8787/v1/devices \
  -H 'content-type: application/json' \
  -d '{"id":"11111111-1111-4111-8111-111111111111","teams":["Blue Jays"]}'
```

See [`server/README.md`](server/README.md) for env vars and more detail.

---

## Technical details

| Component | Description |
|-----------|-------------|
| Language | Swift (app), TypeScript (server) |
| App frameworks | SwiftUI, AppKit, Combine, Foundation |
| Networking | `URLSession` (app); Node HTTP + SSE (server) |
| Graphics | SVGView for team logos |
| Data source | MLB Stats API |
| Persistence | `AppStorage` / `UserDefaults` (app); Postgres (server) |
| Platform | macOS 13.0+ |
| CI | Xcode unit tests + server `npm test` on PRs and `main` |

No login or account is required for the core overlay experience. Preferences stay on your Mac. The optional backend only stores a device id, team subscriptions, and game/notification state.

---

## Project layout

```
OnDeck/                 SwiftUI macOS app
  Models/               GameState + MLBResponseParser
  LiveUpdatesClient.swift   Backend register + SSE
  OverlayView.swift     Scorebug UI (incl. pitch count)
  MLBStatsService.swift Overlay windows + polling
OnDeckTests/            Parser and game-state tests
server/                 Postgres + Node poller/worker
.github/workflows/      CI for app and server
```

---

GO JAYS GO!
