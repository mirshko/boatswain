# Boatswain

A macOS menu bar app for Fathom Analytics. Keep an eye on your site stats without ever leaving your keyboard.

## Features

- **Live visitor count** in the menu bar — always visible at a glance
- **Dashboard stats** (today, last week) for your main site, refreshed automatically
- **All your sites** in the menu — hover to see live visitors and quick stats
- **Configurable refresh** rates for both live visitors and dashboard data
- **Open your Fathom dashboard** with one click
- **Privacy-first** — no tracking, no telemetry, no data leaves your machine except API requests to Fathom

## Requirements

- macOS 14+
- A [Fathom Analytics](https://usefathom.com) account

## Getting Started

1. Open Fathom Analytics and go to **Settings → API**
2. Generate a **read-only API key** (site-wide access — "Site specific" keys won't work)
3. Open Boatswain and paste the key into **Settings**
4. Select your active site from the dropdown
5. That's it — your live visitor count appears in the menu bar

## Tips

- Use a **read-only API key** — Boatswain only fetches data, never writes
- Adjust refresh rates in Settings if you're hitting API rate limits
- Other sites' stats are fetched when you open their submenu, giving you fresh data every time

## Prior Art

- [Pulse](https://pulsestats.app) by [Vadim Demedes](https://github.com/vadimdemedes) — a macOS menu bar app for Plausible Analytics that inspired this project
