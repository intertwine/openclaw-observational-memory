# 🧠 Observational Memory for OpenClaw

**Give your AI agent humanlike long-term memory — no RAG, no embeddings, no databases.**

Two background agents (Observer + Reflector) continuously compress your conversation history into dense, prioritized memory files. Your agent reads these on startup and instantly has full context about you, your projects, your preferences, and what happened while it was "asleep."

Achieves **5–40× compression** over raw conversation history while preserving what matters: facts, preferences, decisions, emotional tone, and project context. Scored **SOTA on [LongMemEval](https://arxiv.org/abs/2410.10813)**.

> Inspired by [Mastra's Observational Memory](https://mastra.ai/docs/memory/observational-memory) — adapted and extended for the [OpenClaw](https://openclaw.ai) ecosystem.

---

## How It Works

```
  Conversation                     Observations                   Reflections
  (raw messages)                   (compressed notes)             (long-term memory)
                                                                  
  ┌──────────────┐  Observer       ┌──────────────┐  Reflector   ┌──────────────┐
  │ Hey, can you │  (every 15m)   │ 🔴 14:30 User│  (daily)     │ ## Identity  │
  │ help me set  │ ────────────►  │ setting up   │ ──────────►  │ Name: Alex   │
  │ up Postgres  │                │ PostgreSQL   │              │ Role: Backend│
  │ for the new  │                │ for project  │              │ dev          │
  │ project? I   │                │ "Atlas." Pre-│              │              │
  │ tried SQLite │                │ fers Postgres│              │ ## Projects  │
  │ but it can't │                │ over SQLite  │              │ Atlas: Migra-│
  │ handle the   │                │ for concurr- │              │ ted SQLite → │
  │ concurrency  │                │ ency reasons.│              │ PostgreSQL   │
  │ we need...   │                │              │              │              │
  │ [200+ more   │                │ 🟡 14:45 De- │              │ ## Prefs     │
  │  messages]   │                │ bugging conn │              │ 🔴 Prefers   │
  │              │                │ pool config  │              │ Postgres for │
  └──────────────┘                └──────────────┘              │ prod workloads│
                                                                └──────────────┘
  ~50K tokens                      ~2K tokens                    ~500 tokens
```

**Three tiers of memory, each more compressed than the last:**

| Tier | Updated | Retention | Size | Contents |
|------|---------|-----------|------|----------|
| **Raw Messages** | Real-time | Session only | ~50K tokens/day | Full conversation |
| **Observations** | Every 15 min | 7 days | ~2K tokens/day | Timestamped, prioritized notes |
| **Reflections** | Daily | Indefinite | 200–600 lines total | Stable identity, projects, preferences |

---

## Example Output

### Observations (`memory/observations.md`)

```markdown
# Observations

## 2026-02-10

### Current Context
- **Active task:** Migrating Atlas project from SQLite to PostgreSQL
- **Mood/tone:** Focused, slightly frustrated with connection pooling
- **Key entities:** Atlas, PostgreSQL, PgBouncer, Render.com
- **Suggested next:** Help verify connection pool settings work under load

### Observations
- 🔴 14:30 User is migrating the Atlas project from SQLite to PostgreSQL
  - 🔴 14:30 Reason: SQLite can't handle the concurrent writes they need
  - 🟡 14:35 Using Render.com managed PostgreSQL instance
- 🔴 14:42 User prefers PostgreSQL over SQLite for production workloads
- 🟡 14:45 Debugging connection pool exhaustion — PgBouncer max_client_conn was set too low
  - 🟡 14:52 Resolved: increased to 200 connections, switched to transaction mode
- 🟢 15:00 Quick weather check — no follow-up needed
- 🔴 15:10 User wants to add full-text search to Atlas
  - 🟡 15:10 Considering pg_trgm vs tsvector — leaning toward tsvector
```

### Reflections (`memory/reflections.md`)

```markdown
# Reflections — Long-Term Memory

*Last updated: 2026-02-10 04:00 UTC*

## Core Identity
- **Name:** Alex Chen
- **Role:** Backend engineer at a Series B startup
- **Communication style:** Direct, technical, appreciates concise answers
- **Working hours:** ~09:00–18:00 PST, occasional evening sessions
- **Preferences:** PostgreSQL, Python, FastAPI, prefers CLI over GUI
- **Pet peeves:** Verbose explanations when a code snippet would do

## Active Projects

### Atlas
- **Status:** Active
- **Started:** ~Jan 2026
- **Stack:** Python, FastAPI, PostgreSQL (migrated from SQLite ~Feb 2026)
- **Key decisions:** PostgreSQL for concurrency; PgBouncer in transaction mode; tsvector for search
- **Current state:** Database migration complete, adding full-text search

## Preferences & Opinions
- 🔴 PostgreSQL over SQLite for anything production
- 🔴 Prefers code examples over explanations
- 🔴 Uses Render.com for managed infrastructure
- 🟡 Interested in PgBouncer vs pgpool — chose PgBouncer for simplicity

## Relationship & Communication
- Likes brief, direct answers — expand only when asked
- Appreciates when the agent catches potential issues proactively
- Uses humor when frustrated (dry/sarcastic)
```

---

## Quick Start

### Prerequisites

- [OpenClaw](https://openclaw.ai) installed and running
- `openclaw` CLI available in your PATH

### Install

```bash
git clone https://github.com/intertwine/observational-memory.git
cd observational-memory
bash scripts/install.sh
```

This will:
1. Create `memory/observations.md` and `memory/reflections.md` in your workspace
2. Set up two cron jobs: Observer (every 15 min) and Reflector (daily at 04:00 UTC)

### Configure

```bash
# Custom model
bash scripts/install.sh --model anthropic/claude-sonnet-4-20250514

# Custom schedule
bash scripts/install.sh --observer-interval "*/30 * * * *"  # every 30 min
bash scripts/install.sh --reflector-schedule "0 6 * * *"     # 06:00 UTC daily

# Uninstall
bash scripts/uninstall.sh
bash scripts/uninstall.sh --purge  # also removes memory files
```

### Wire Up Your Agent

Add these lines to your `AGENTS.md` (or equivalent startup instructions):

```markdown
## Every Session
...
5. Read `memory/observations.md` — recent compressed observations (auto-maintained by Observer)
6. Read `memory/reflections.md` — long-term condensed memory (auto-maintained by Reflector)
```

That's it. Your agent now has persistent, compressed memory.

---

## Architecture

```
┌─────────────────┐  every 15 min   ┌──────────────────┐
│   Main Agent    │ ◄── reads ───── │  Observer Agent   │
│   Session       │                 │  (cron, isolated) │
└────────┬────────┘                 └────────┬──────────┘
         │                                   │ writes
         │ reads on startup          ┌───────▼──────────┐
         └──────────────────────────►│ memory/           │
                                     │  observations.md  │
                                     │  reflections.md   │
                                     └───────┬──────────┘
                                             │ reads + trims
                                     ┌───────▼──────────┐
                                     │ Reflector Agent   │
                                     │ (daily cron)      │
                                     └──────────────────┘
```

### Observer Agent
- Runs as an OpenClaw cron job (default: every 15 minutes)
- Reads recent session history from the main agent session
- Compresses unprocessed messages into timestamped, prioritized notes
- Appends to `memory/observations.md`
- Maintains a "Current Context" block with active tasks, mood, and suggested next actions

### Reflector Agent
- Runs daily (default: 04:00 UTC)
- Reads all observations and existing reflections
- Merges, promotes, demotes, and archives entries based on frequency and recency
- Overwrites `memory/reflections.md` with a clean, condensed long-term memory document
- Trims observations older than 7 days

### Priority System

| Level | Meaning | Examples | Retention |
|-------|---------|----------|-----------|
| 🔴 | Important / persistent | User facts, decisions, project architecture | Months+ |
| 🟡 | Contextual | Current tasks, in-progress work, open questions | Days–weeks |
| 🟢 | Minor / transient | Greetings, routine checks, small talk | Hours |

---

## Customization

### Tuning Compression

Edit the prompts in `reference/` to adjust:
- **What gets captured** — modify the priority definitions in `observer-prompt.md`
- **How aggressively observations are merged** — adjust the merge/promote/archive rules in `reflector-prompt.md`
- **Target size** — the reflector aims for 200–600 lines; change this in the prompt

### Adjusting Frequency

```bash
openclaw cron list                    # see current jobs
openclaw cron edit observer-memory    # modify observer schedule
openclaw cron edit reflector-memory   # modify reflector schedule
```

### Manual Triggers

```bash
openclaw cron trigger observer-memory    # run observer now
openclaw cron trigger reflector-memory   # run reflector now
```

### Model Selection

The install script defaults to `anthropic/claude-sonnet-4-20250514`. Both agents work well with any capable model — Sonnet-class or better is recommended for the observer, while the reflector benefits from stronger reasoning (Opus-class) for complex merging decisions.

---

## File Structure

```
observational-memory/
├── README.md              # This file
├── LICENSE                # MIT
├── SKILL.md               # OpenClaw skill integration guide
├── reference/
│   ├── observer-prompt.md # System prompt for the Observer agent
│   └── reflector-prompt.md# System prompt for the Reflector agent
└── scripts/
    ├── install.sh         # Automated setup
    └── uninstall.sh       # Clean removal
```

---

## FAQ

**Q: Does this replace RAG / vector search?**
A: For personal assistant use cases, yes. Observational memory works better for remembering *about a person* — their preferences, projects, communication style. RAG is better for searching large document collections. They're complementary.

**Q: How much does it cost to run?**
A: The observer processes only new messages each run (~100–500 input tokens typical). The reflector reads more but runs only once daily. Expect ~$0.05–0.20/day with Sonnet-class models.

**Q: What if the observer misses something?**
A: The observer errs on the side of keeping observations ("when in doubt, keep it"). The reflector handles cleanup. You can also manually edit `memory/observations.md` at any time.

**Q: Can I use this outside OpenClaw?**
A: The prompts are generic and work with any agent framework that supports cron-like scheduling and file-based memory. The install script is OpenClaw-specific, but the pattern is portable.

---

## Credits

- **Inspired by** [Mastra's Observational Memory](https://mastra.ai/docs/memory/observational-memory) — the original OM pattern that achieved SOTA on LongMemEval
- **Built for** the [OpenClaw](https://openclaw.ai) community
- **License:** MIT — fork it, customize it, ship it

---

*Made with 🧠 by [Intertwine](https://github.com/intertwine)*
