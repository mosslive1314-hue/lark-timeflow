# 🪞 time-mirror

**A time mirror, not a time cop.**

> Automatically tracks macOS app usage, writes time blocks to Apple Calendar, fills in gaps nightly, and generates weekly reviews.
> See where your time actually goes — then decide for yourself.

<br>

## ✨ Philosophy

```
There are only 24 hours in a day.
8 hours of sleep. 8 hours of living. 8 hours of work & learning.
Where you spend time is what you get back.
```

time-mirror won't tell you what you *should* do — it shows you what you *did*.

**It's a mirror, not a manager.**

<br>

## 🎯 What It Does

```
┌──────────────────────────────────────────────────────────┐
│                      time-mirror                          │
│                                                           │
│  📊 Auto-collect       🗓️ Write to Calendar   📋 Nightly │
│  macOS app usage       Apple Calendar         Fill gaps   │
│  Chrome browsing       → iCloud sync          User reply  │
│                        → visible on iPhone                │
│                        → visible on Lark      📈 Weekly   │
│                                               Review      │
└──────────────────────────────────────────────────────────┘
```

<br>

## 🖥️ How It Works

### Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌────────────────┐
│  macOS       │     │  time-mirror │     │  Apple         │
│  knowledgeC  │────▶│  Collect +   │────▶│  Calendar      │
│  .db         │     │  Aggregate   │     │  (iCloud sync) │
├──────────────┤     │              │     ├────────────────┤
│  Chrome      │────▶│  30min grain │     │  📱 iPhone     │
│  History     │     │  App classify│     │  📘 Lark/Feishu│
└──────────────┘     └──────────────┘     └────────────────┘
```

### How Does macOS Know What You're Using?

macOS has a built-in **Knowledge framework** that automatically logs foreground app usage in `knowledgeC.db`. time-mirror simply reads this existing database — **no monitoring software installed**.

```sql
-- This is the data time-mirror reads
SELECT app_name, start_time, end_time, duration
FROM knowledgeC.db
WHERE stream = '/app/usage'
```

<br>

## 🚀 Quick Start

### Mode 1: Local (Recommended)

> OpenClaw runs on your daily Mac

**Zero config.** Just run:

```bash
# Collect today's data
./scripts/collect.sh

# Collect a specific date
./scripts/collect.sh 2024-03-15
```

### Mode 2: Remote

> OpenClaw runs on a different Mac (e.g., a home server); your daily driver is a separate machine

On your daily Mac, run:

```bash
crontab -e
```

Add these two lines (sync every 30 minutes):

```cron
*/30 * * * * cp ~/Library/Application\ Support/Knowledge/knowledgeC.db ~/Library/Mobile\ Documents/com~apple~CloudDocs/knowledgeC_sync.db
*/30 * * * * cp ~/Library/Application\ Support/Google/Chrome/Default/History ~/Library/Mobile\ Documents/com~apple~CloudDocs/chrome_history_sync.db
```

Data syncs to the OpenClaw Mac automatically via **iCloud Drive**.

```
┌─────────────┐   iCloud    ┌─────────────┐
│  Daily Mac   │───────────▶│  OpenClaw Mac│
│  knowledgeC  │   auto-sync │  Read + Agg  │
│  Chrome Hist │            │  Write to Cal│
└─────────────┘             └─────────────┘
```

### Auto-Detection

The skill automatically picks the right mode:

```bash
./scripts/detect_mode.sh
# Output: "local" or "remote"
```

<br>

## 📊 Output Examples

### Daily Timeline

```
⏰ Daily Timeline | 2024-03-15

08:04-08:22  💰 Chrome browsing + work chat
08:22-10:03  ❓ Blank (1h41m) ← What were you doing?
10:03-10:58  👀 WeChat + Lark + Slack (communication)
11:00-11:46  💰 Figma design (with chat interrupts)
11:46-14:20  ❓ Blank (2h34m) ← Lunch break?
14:20-15:20  🛜 Lark: discussing product strategy
15:06-15:17  🌳 Chrome: X/Twitter AI content
```

### Daily Summary

```
📊 Daily Summary

💰 Work       1h04m  ██████████░░░░░░  28%
👀 Comms        55m  ████████░░░░░░░░  23%
🛜 Building   1h00m  █████████░░░░░░░  25%
🌳 Learning     11m  █░░░░░░░░░░░░░░░   5%
❓ Blank      4h16m  ████████████████  To fill
```

### Weekly Review

```
📈 Weekly Distribution | 3/11 - 3/17

🛜 Building    12h  ████████████████  25%
💰 Work        10h  █████████████░░░  21%
👀 Comms        8h  ██████████░░░░░░  17%
🌳 Learning     5h  ██████░░░░░░░░░░  10%
🥬 Life         6h  ████████░░░░░░░░  13%
🎮 Leisure      3h  ████░░░░░░░░░░░░   6%
🧠 Other        4h  █████░░░░░░░░░░░   8%

vs last week: 🛜Building +3h ↑ | 🎮Leisure -2h ↓ | Trending well ✅
```

<br>

## 🗓️ Apple Calendar Integration

time-mirror writes time blocks to your **Apple Calendar**, which syncs via iCloud to all your devices:

```
Apple Calendar ──iCloud──▶ iPhone Calendar
                         ▶ Lark/Feishu Calendar (if linked)
                         ▶ All other devices
```

### Category Mapping

Customize how apps map to calendar categories (edit `references/app_categories.md`):

| App | Calendar |
|-----|----------|
| Figma, Sketch | 💰 Work |
| WeChat, Lark, Slack | 👀 Communication |
| Chrome (content-based) | 🌳 Learning / 💰 Work / 🎮 Leisure |
| TikTok, Bilibili | 🎮 Leisure |
| Obsidian | 🌳 Learning / 🛜 Building |

Chrome classification uses browsing history for smart inference:

```
Chrome + GitHub/HN       → 🌳 Learning
Chrome + Figma docs      → 💰 Work
Chrome + TikTok/Reddit   → 🎮 Leisure
Chrome + Notion/Lark     → 🛜 Building
```

<br>

## 📊 Lark Bitable Dashboard

With [lark-cli](https://github.com/nicepkg/lark-cli) or the Lark Bitable API, time-mirror can write data to a Lark multidimensional table and auto-generate visual dashboards.

### Writing to Lark

```
┌──────────────┐     ┌──────────────┐     ┌───────────────────┐
│  time-mirror │     │  Lark        │     │  Dashboard        │
│  Collect +   │────▶│  Bitable     │────▶│  Pie / Bar charts │
│  Aggregate   │     │  Structured  │     │  Trends / Compare │
└──────────────┘     └──────────────┘     └───────────────────┘
```

### Table Schema

| Field | Type | Description |
|-------|------|-------------|
| Time Slot | Text (primary) | `08:04-08:22 \| 💰 Work` |
| Category | Single Select | 🛜 Building / 🌳 Learning / 💰 Work / 👀 Comms / 🎮 Leisure / ❓ Blank ... |
| Description | Text | `Figma design (with chat interrupts) 46m` |
| Data Source | Single Select | 🤖 Auto-collected / ✏️ Manual / 📱 Screenshot OCR |

### Dashboard Preview

Create a **Dashboard view** in Lark Bitable for auto-generated visualizations:

```
┌─────────────────────────────────────────────┐
│  📊 Today's Time Distribution                │
│                                              │
│  🛜 Building ████████████████  42%  1h40m   │
│  👀 Comms    ██████████░░░░░░  23%  55m     │
│  💰 Work     ██████████░░░░░░  27%  1h04m   │
│  🌳 Learning ██░░░░░░░░░░░░░░   5%  11m    │
│  ❓ Blank    To fill                         │
│                                              │
├─────────────────────────────────────────────┤
│  📈 Weekly Trend                             │
│                                              │
│  Mon  ██████████████████████  8h            │
│  Tue  ████████████████░░░░░░  6h            │
│  Wed  ████████████████████░░  7h            │
│  Thu  ██████████████░░░░░░░░  5h (ongoing)  │
│                                              │
└─────────────────────────────────────────────┘
```

### Multi-Device Access

Lark Bitable natively supports cross-platform viewing:

```
Lark Bitable (data source)
├── 📱 Mobile Lark App → Check time distribution on the go
├── 💻 Desktop Lark → Full dashboard view
└── 🌐 Browser → Share link with anyone
```

> **Apple Calendar vs Lark Bitable:** Calendar is great for timeline views (Gantt-style). Bitable is great for analytics (pie charts, bar charts). time-mirror writes to both — they complement each other.

<br>

## 📱 Mobile Data

Currently **macOS only**. iPhone/iPad Screen Time data is sandboxed by Apple and cannot be auto-collected.

**Workarounds:**
- 📸 Send a Screen Time screenshot to your AI agent — it can OCR and merge the data
- ⏳ Wait for the OpenClaw iOS Node release for native auto-collection

<br>

## 📂 Project Structure

```
time-mirror/
├── SKILL.md                     # OpenClaw skill definition (AI reads this)
├── README.md                    # 中文文档
├── README_EN.md                 # English docs (you are here)
├── references/
│   └── app_categories.md        # App → Calendar category mapping (customizable)
└── scripts/
    ├── detect_mode.sh           # Auto-detect local/remote mode
    └── collect.sh               # Data collection script
```

<br>

## ⚠️ Caveats

| Issue | Details |
|-------|---------|
| iCloud Sync Delay | In remote mode, iCloud files may take a few minutes to sync; the script handles this |
| Chrome Lock | Chrome locks its History file while running; the copy may be slightly stale |
| WAL Mode | knowledgeC.db uses WAL; remote copies may miss a few recent records — acceptable |
| I/O Error | iCloud-hosted db files can't be read directly with SQLite; must `dd` copy to /tmp first |
| Privacy | All data processed locally. Nothing uploaded to any cloud service |

<br>

## 🧘 Design Philosophy

> Most time tracking tools: Week 1 excited → Week 2 forgetting → Week 3 abandoned.

time-mirror is designed for **zero friction**:

1. **No manual logging** — data is auto-collected
2. **No app to open** — data writes to your calendar automatically
3. **No flow interruption** — only asks about gaps once per evening
4. **No judgment** — 3 hours of TikTok? Noted. You decide what to change

Advice from an Austrian economist:

> *"The skill must be a tool, never a master."* — Mises (probably)

<br>

## 🤝 Works with OpenClaw

time-mirror is designed as an [OpenClaw](https://github.com/openclaw/openclaw) skill. Once installed, your AI agent auto-triggers on:

- "What did I do today?"
- "Track my time"
- "How's my time distribution this week?"
- "Write to calendar"

Scripts also work standalone for data collection.

<br>

## 📄 License

MIT

---

*Built with 🍡 by a human and their AI assistant.*
