<p align="center">
  <img src="docs/AppIcon.png" width="128" alt="Boatswain">
</p>

<h1 align="center">Boatswain</h1>

<p align="center">A macOS menu bar app for Fathom Analytics.</p>

## Screenshots

<p align="center">
  <img src="docs/Boatswain%20No%20Active%20Site.png" width="45%" alt="No Active Site">&nbsp;
  <img src="docs/Boatswain%20Active%20Site.png" width="45%" alt="Active Site">
</p>
<p align="center">
  <img src="docs/Boatswain%20View%20Other%20Site.png" width="45%" alt="View Other Site">
</p>

## Features

- **Live visitor count** in the menu bar — always visible at a glance
- **Dashboard stats** (today, last week) for your main site, refreshed automatically
- **All your sites** in the menu — hover to see live visitors and quick stats
- **Configurable refresh** rates for both live visitors and dashboard data
- **Open your Fathom dashboard** with one click
- **Privacy-first** — no tracking, no telemetry, no data leaves your machine except API requests to Fathom

## Requirements

- macOS 15+
- A [Fathom Analytics](https://usefathom.com) account

## Download

Get the latest release from the [releases page](https://github.com/mirshko/boatswain/releases/latest).

## Install

1. Download `Boatswain.zip` from the latest release
2. Unzip the file
3. Move `Boatswain.app` into your `/Applications` folder
4. Open **System Settings → Privacy & Security** and click **Open Anyway** next to the security warning for Boatswain (the app isn't signed with an Apple Developer account)
5. Open Boatswain and paste your Fathom API key in **Settings**

## Getting Started

1. Open Fathom Analytics and go to **Settings → API**
2. Generate a **read-only API key** (site-wide access — "Site specific" keys won't work)
3. Open Boatswain and paste the key into **Settings**
4. Select your active site from the dropdown
5. That's it — your live visitor count appears in the menu bar

## Tips

- Use a **read-only API key** — Boatswain only fetches data, never writes
- Adjust refresh rates in Settings if you're hitting API rate limits
- All sites' data refreshes in the background at your configured dashboard refresh rate

## Prior Art

- [Pulse](https://pulsestats.app) by [Vadim Demedes](https://github.com/vadimdemedes) — a macOS menu bar app for Plausible Analytics that inspired this project
