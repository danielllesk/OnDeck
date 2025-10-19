# 🧢 OnDeck — Live MLB Game Tracker for macOS

**OnDeck** is a beautifully designed macOS app that keeps baseball fans up to date with every pitch, hit, and run. Right from your desktop!  
It provides live score overlays, real-time stats, and instant updates for your favorite teams during the MLB season.

---
## DEMO
[![Watch the Demo](OnDeckLogo.png)](https://drive.google.com/file/d/1A2ZumdYbso7bBaT-2-2EIHGWRHYQ5L9h/view?usp=sharing)
---
## ⚾️ Overview

Baseball is best enjoyed in real time, but most apps require you to open a browser, load ads, and dig through menus.  
**OnDeck** brings the game to you with lightweight live score overlays that update automatically every 10 seconds.

You can:
- 🧢 **Select your favorite teams** to follow throughout the season.  
- 🎯 **Get notified when a game goes live.**  
- 🪶 **Float live “scorebug” windows** that display inning, bases, count, pitcher, and batter info.  
- 🧮 **Track real-time stats**, including hits, at-bats, and batting averages.  
- 💾 **Save preferences locally**, so your selections persist across sessions.

---

## 🖥️ How It Works

OnDeck uses the official **[MLB Stats API](https://statsapi.mlb.com)** a public data source provided by Major League Baseball  to retrieve:
- Live scores and inning status  
- Batter and pitcher statistics  
- Base occupancy and count data  
- Real-time game events (outs, balls, strikes)

The app fetches this data using Apple’s native **`URLSession`** networking layer, ensuring smooth, secure, and efficient communication.  
All updates occur on a background thread to keep your Mac responsive while games refresh every 10 seconds.

No login or account is required! OnDeck never stores personal data.  
All preferences are securely stored locally on your Mac via **AppStorage** (using `UserDefaults` under the hood).

---

## 🎨 Design Philosophy

OnDeck is built with **SwiftUI** and **AppKit**, combining the modern look of macOS with the flexibility of native rendering.

The floating overlays use:
- **NSWindow** for lightweight, movable scorecards
- **SVGView** for scalable team logos
- **Combine publishers** for reactive updates as data changes
- **Timers and async tasks** to poll live data without blocking the UI

Each overlay is designed to:
- Float above other windows (but never interfere with interaction)
- Auto-close when a game ends
- Remain open independently of the main app window
- Moveable! if you dont like it in the right corner you can move it anywhere you want on your screen
- Update seamlessly in real time

---

## 🧠 Technical Details

| Component | Description |
|------------|-------------|
| **Language** | Swift |
| **Frameworks** | SwiftUI, AppKit, Combine, Foundation |
| **Networking** | `URLSession` (async background calls) |
| **Graphics** | SVGView for team logos |
| **Data Source** | MLB Stats API (public endpoint) |
| **Platform** | macOS 13.0 or later |

---

## 🧩 How Live Updates Work

1. **Tracking Begins:**  
   When you click **“Save & Start Tracking”**, OnDeck saves your selected teams and begins polling MLB’s live schedule endpoint.

2. **Game Detection:**  
   Every 10 seconds, the app checks for live or in-progress games involving your teams.

3. **User Prompt:**  
   When one of your teams goes live, you’re prompted to open a **floating score overlay**.

4. **Detailed Updates:**  
   Once an overlay is active, OnDeck starts calling each game’s `feed/live` endpoint to retrieve:
   - Batter name and season, or postseason, average  
   - Pitcher name and pitch count  
   - Current base occupancy  
   - Count (balls, strikes, outs)  
   - Inning and team scores  

5. **Automatic Refresh:**  
   Overlays refresh automatically — no manual input required.

6. **Cleanup:**  
   When a game concludes, OnDeck closes the overlay and removes the entry from live tracking.

---
GO JAYS GO!
