# 🧠 Observational Memory for OpenClaw

**Give your AI agent humanlike long-term memory with hybrid search — no RAG pipelines, no databases, no infrastructure.**

Two background agents (Observer + Reflector) compress your conversation history into dense, prioritized memory files. [QMD](https://github.com/tobi/qmd) hybrid search (BM25 + vectors + reranking) makes those compressed memories instantly findable. Your agent reads them on startup and has full context about you, your projects, your preferences, and what happened while it was "asleep."

The compressed observations achieve **5–40× token reduction** while preserving what matters — and they're actually **better search targets** than raw conversation. Dense, pre-scored notes produce higher-precision results than searching through thousands of noisy messages.

> Inspired by [Mastra's Observational Memory](https://mastra.ai/docs/memory/observational-memory) (SOTA on [LongMemEval](https://arxiv.org/abs/2410.10813)) — adapted and extended with hybrid search for the [OpenClaw](https://openclaw.ai) ecosystem.

---

## How It Works

The system has two layers: **compression** (Observer + Reflector) and **retrieval** (QMD hybrid search). Together they solve the full memory problem — writing dense memories *and* finding them when you need them.

```
  Conversation        Observer          Memory Files           QMD Hybrid Search
  (raw messages)      (every 30m)       (compressed)           (BM25 + vectors + reranking)

  ┌──────────────┐   ┌───────────┐     ┌──────────────┐      ┌──────────────┐
  │ Hey, can you │   │           │     │ 🔴 14:30 User│      │              │
  │ help me set  │   │ Compress  │     │ setting up   │      │ BM25 index   │
  │ up Postgres  │──►│ & score   │────►│ PostgreSQL   │─────►│ Vector embed │
  │ for the new  │   │ priorities│     │ for project  │      │ LLM reranker │
  │ project?...  │   │           │     │ "Atlas"      │      │              │
  │ [200+ msgs]  │   └───────────┘     └──────┬───────┘      └──────┬───────┘
  └──────────────┘                            │                      │
                                              │                      │
  ~50K tokens/day     Reflector        ┌──────▼───────┐      memory_search
                      (daily)          │ ## Identity  │      "What was that
                     ┌───────────┐     │ Name: Alex   │       Postgres decision?"
                     │ Condense  │────►│ ## Projects  │             │
                     │ & merge   │     │ Atlas: PG    │      ┌──────▼───────┐
                     └───────────┘     │ ## Prefs     │      │ Top results  │
                                       │ 🔴 Postgres  │      │ with citations│
                                       └──────────────┘      └──────────────┘
                                        ~500 tokens total
```

**Three tiers of memory, each more compressed than the last — all searchable via QMD:**

| Tier | Updated | Retention | Size | Contents |
|------|---------|-----------|------|----------|
| **Raw Messages** | Real-time | Session only | ~50K tokens/day | Full conversation |
| **Observations** | Every 30 min | 7 days | ~2K tokens/day | Timestamped, prioritized notes |
| **Reflections** | Daily | Indefinite | 200–600 lines total | Stable identity, projects, preferences |

### Why Compression + Hybrid Search

Most memory systems choose between compression (summaries) and retrieval (RAG). This system does both, and the combination is better than either alone:

- **Compressed observations are better search targets.** Stripping filler and scoring by priority means QMD searches through signal, not noise.
- **BM25 catches what vectors miss.** Project names, error codes, API endpoints, specific tools — exact-match search finds these instantly. Vector search alone often can't.
- **Vectors catch what BM25 misses.** "That database discussion last week" finds your PostgreSQL migration notes even though the word "database" never appears in them.
- **Local reranking** scores results by actual relevance, not just keyword or embedding similarity.

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
- 🔴 15:10 User wants to add full-text search to Atlas
  - 🟡 15:10 Considering pg_trgm vs tsvector — leaning toward tsvector
```

### Reflections (`memory/reflections.md`)

```markdown
# Reflections — Long-Term Memory

*Last updated: 2026-02-10 04:00 UTC*
*Last reflected: 2026-02-10 15:10 UTC*

## Core Identity
- **Name:** Alex Chen
- **Role:** Backend engineer at a Series B startup
- **Communication style:** Direct, technical, appreciates concise answers
- **Working hours:** ~09:00–18:00 PST, occasional evening sessions
- **Preferences:** PostgreSQL, Python, FastAPI, prefers CLI over GUI

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
- 🟡 Interested in PgBouncer vs pgpool — chose PgBouncer for simplicity
```

---

## Quick Start

### Prerequisites

- [OpenClaw](https://openclaw.ai) installed and running
- `openclaw` CLI available in your PATH

### Install

```bash
git clone https://github.com/intertwine/openclaw-observational-memory.git
cd openclaw-observational-memory
bash scripts/install.sh
```

This will:
1. Create `memory/observations.md` and `memory/reflections.md` in your workspace
2. Set up two cron jobs: Observer (every 30 min) and Reflector (daily at 04:00 UTC)

### Enable Hybrid Search (Recommended)

```bash
bash scripts/enable-qmd.sh
```

This installs [QMD](https://github.com/tobi/qmd) and configures OpenClaw to use hybrid search (BM25 + vectors + reranking) over your memory files. QMD auto-indexes observations, reflections, and daily memory files every 5 minutes.

**Resource requirements:**
- **Full setup:** ~2 GB RAM for local GGUF models (embedding + reranking)
- **Lighter setup:** BM25 keyword search works with zero extra RAM; vector embeddings fall back to OpenAI API if local models can't load
- **Disk:** ~1 GB for model files on first run

To disable: `bash scripts/enable-qmd.sh --disable`

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

That's it. Your agent now has persistent, compressed, searchable memory.

---

## Standalone CLI (`om`)

If you're using Claude Code or Codex CLI and want to run the Observer/Reflector outside of OpenClaw, the companion [`observational-memory`](https://github.com/intertwine/observational-memory) Python package provides a standalone CLI:

```bash
# Install
pip install observational-memory
# or: uv tool install observational-memory

# Run observer on all recent transcripts
om observe

# Run reflector to condense observations into reflections
om reflect

# Backfill from historical transcripts
om backfill

# Search memory
om search "postgres migration"

# Show status
om status
```

The `om` CLI includes:
- **Transcript parsing** for Claude Code (`.jsonl`) and Codex sessions
- **Backfill** — process all historical transcripts in one command
- **Incremental reflection** — only processes new observations since `Last reflected` timestamp, with automatic chunking for large inputs
- **Pluggable search** — BM25 (default), QMD (hybrid), or none
- **Session hooks** — `om context` for automatic memory injection at session start

See the [`observational-memory` repo](https://github.com/intertwine/observational-memory) for full documentation.

---

## Architecture

```
┌─────────────────┐  every 30 min   ┌──────────────────┐
│   Main Agent    │ ◄── reads ───── │  Observer Agent   │
│   Session       │                 │  (cron, isolated) │
└────────┬────────┘                 └────────┬──────────┘
         │                                   │ writes
         │ reads on startup          ┌───────▼──────────┐
         │                           │ memory/           │
         │                           │  observations.md  │◄──── QMD indexes
         └──────────────────────────►│  reflections.md   │      (BM25 + vectors
                                     └───────┬──────────┘       + reranking)
                                             │ reads + trims         │
                                     ┌───────▼──────────┐           │
                                     │ Reflector Agent   │     memory_search
                                     │ (daily cron)      │     finds relevant
                                     └──────────────────┘      memories on demand
```

### Observer Agent
- Runs as an OpenClaw cron job (default: every 30 minutes)
- Reads recent session history from the main agent session
- Compresses unprocessed messages into timestamped, prioritized notes
- Appends to `memory/observations.md` — maintains exactly one `### Observations` block per day
- Maintains a "Current Context" block with active tasks, mood, and suggested next actions
- Filters out noise: heartbeat polls, system messages, cron notifications, and duplicate entries

### Reflector Agent
- Runs daily (default: 04:00 UTC)
- **Incremental updates only** — reads observations from `Last reflected` date onward, not the entire file
- Merges new information into the existing reflections document via surgical edits (add, update, promote, demote, archive)
- Overwrites `memory/reflections.md` with updated `Last updated` and `Last reflected` timestamps
- Trims observations older than 7 days
- When observations are too large for a single pass (e.g., after backfill), automatically chunks by date section and folds incrementally

### QMD Hybrid Search
- [QMD](https://github.com/tobi/qmd) indexes all memory files automatically (5-minute refresh)
- **BM25** catches exact matches: project names, error codes, tool names, URLs
- **Vector search** catches semantic matches: "that auth issue" finds your OAuth debugging notes
- **LLM reranker** scores results by actual relevance
- Falls back gracefully: if QMD is unavailable, OpenClaw uses its built-in vector search

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
- **What gets filtered** — the Observer has a "Never Log" list (heartbeats, cron notifications, etc.)
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

The install script defaults to `anthropic/claude-sonnet-4-20250514`. Both agents work well with any capable model. Sonnet-class or better is recommended for the observer. The reflector benefits from stronger reasoning for complex merging, but works well with smaller models too (we run ours on Kimi K2.5, free tier).

---

## File Structure

```
openclaw-observational-memory/
├── README.md              # This file
├── CLAUDE.md              # Claude Code guidance
├── LICENSE                # MIT
├── SKILL.md               # OpenClaw skill integration guide
├── docs/
│   └── code-and-context-article.md
├── reference/
│   ├── observer-prompt.md # System prompt for the Observer agent
│   └── reflector-prompt.md# System prompt for the Reflector agent
└── scripts/
    ├── install.sh         # Automated setup (Observer + Reflector)
    ├── uninstall.sh       # Clean removal
    └── enable-qmd.sh     # Enable QMD hybrid search
```

---

## FAQ

**Q: Do I need QMD?**
A: Observational memory works well standalone — your agent reads the compressed files on startup and has full context. QMD adds the ability to *search* across weeks or months of observations when the agent needs to recall something specific. For agents with long histories or many projects, hybrid search makes a real difference.

**Q: Does this replace RAG?**
A: For personal assistant memory, yes. Observational memory + QMD handles remembering *about a person* (preferences, projects, communication style) better than traditional RAG. For searching large document collections, RAG is still the right tool.

**Q: How much does it cost to run?**
A: The observer processes only new messages each run (~100–500 input tokens typical). The reflector reads more but runs only once daily, and only processes observations since its last run. Expect ~$0.05–0.20/day with Sonnet-class models, or $0 with free-tier models like Kimi K2.5. QMD runs locally with no API costs.

**Q: What if the observer misses something?**
A: The observer errs on the side of keeping observations. The reflector handles cleanup. You can also manually edit `memory/observations.md` at any time.

**Q: What about large observation histories?**
A: The reflector uses **incremental updates** — it reads its own previous output as a stable base and only processes new observations since its last run. This keeps input bounded regardless of total history size, preventing quality degradation from large inputs.

**Q: What happens if the reflector runs on a huge backlog?**
A: The reflector's `Last reflected` timestamp ensures it only processes new observations during normal operation. If the timestamp is missing (first run or after a backfill), the reflector automatically chunks observations by date section and folds them incrementally, preventing the model from being overwhelmed.

**Q: Can I use this outside OpenClaw?**
A: The prompts are generic and work with any agent framework that supports cron-like scheduling and file-based memory. The install script is OpenClaw-specific, but the pattern is portable. See [`observational-memory`](https://github.com/intertwine/observational-memory) for a standalone CLI targeting Claude Code and Codex.

---

## Credits

- **Inspired by** [Mastra's Observational Memory](https://mastra.ai/docs/memory/observational-memory) — the original OM pattern that achieved SOTA on LongMemEval
- **Hybrid search powered by** [QMD](https://github.com/tobi/qmd) by Tobi Lütke — local-first BM25 + vectors + reranking
- **Built for** the [OpenClaw](https://openclaw.ai) community
- **License:** MIT — fork it, customize it, ship it

---

*Made with 🧠 by [Intertwine](https://github.com/intertwine)*
