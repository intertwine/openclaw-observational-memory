---
name: observational-memory
description: >
  Two-tier compressed memory system using Observer and Reflector background agents.
  Replaces raw conversation history with dense, prioritized observations and long-term reflections.
---

# Observational Memory — Skill Guide

## Overview

Two background agents maintain compressed memory files that your main agent reads on startup:

- **`memory/observations.md`** — Timestamped, prioritized notes from recent conversations (updated every 15 min)
- **`memory/reflections.md`** — Condensed long-term memory: identity, projects, preferences (updated daily)

## Installation

```bash
git clone https://github.com/intertwine/observational-memory.git
cd observational-memory
bash scripts/install.sh
```

Or manually: copy the prompts from `reference/` into your skills directory and create cron jobs per the instructions below.

## AGENTS.md Integration

Add to your "Every Session" context loading:

```markdown
## Every Session
...
5. Read `memory/observations.md` — recent compressed observations (auto-maintained by Observer)
6. Read `memory/reflections.md` — long-term condensed memory (auto-maintained by Reflector)
```

## Cron Jobs

The install script creates two cron jobs:

| Job | Schedule | Prompt | Purpose |
|-----|----------|--------|---------|
| `observer-memory` | `*/15 * * * *` | `observer-prompt.md` | Compress recent messages → observations |
| `reflector-memory` | `0 4 * * *` | `reflector-prompt.md` | Condense observations → reflections |

## Configuration

### Model

Default: `anthropic/claude-sonnet-4-20250514`. Override during install:

```bash
bash scripts/install.sh --model anthropic/claude-opus-4-6
```

### Frequency

- **Observer:** `--observer-interval "*/30 * * * *"` (default: every 15 min)
- **Reflector:** `--reflector-schedule "0 6 * * *"` (default: daily at 04:00 UTC)

### Manual Triggers

```bash
openclaw cron trigger observer-memory
openclaw cron trigger reflector-memory
```

## Tuning

- **Observer threshold:** Skips runs with fewer than ~10 new messages (configurable in prompt)
- **Reflector target:** Aims for 200–600 lines in reflections.md (configurable in prompt)
- **Observation retention:** 7 days before the reflector trims old entries

Edit the prompts in `reference/` to adjust priority definitions, compression rules, or output format.

## Enhanced Search with QMD (Optional)

QMD adds hybrid search (BM25 + vectors + reranking) over your compressed memory files, making it easy to recall specific observations from weeks or months ago.

```bash
bash scripts/enable-qmd.sh           # Enable QMD backend
bash scripts/enable-qmd.sh --disable # Revert to default
```

QMD is optional — OM works great standalone. If QMD is unavailable, OpenClaw falls back to built-in vector search. See the [README section on QMD](README.md#enhanced-search-with-qmd-optional) for architecture details and resource requirements.

## Relationship to MEMORY.md

Options:
1. **Replace** MEMORY.md — let observations + reflections be your entire memory system
2. **Supplement** — keep MEMORY.md for manually curated notes alongside auto-generated memory

Option 1 is recommended for most setups.
