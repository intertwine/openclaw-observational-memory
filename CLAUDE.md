# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A two-tier compressed memory system for OpenClaw agents. Two background agents (Observer + Reflector) run on cron schedules to compress raw conversation history into dense memory files that an agent reads on startup.

**This is not a Python/JS/etc. application** — it's a set of prompt files (`reference/`), shell scripts (`scripts/`), and documentation. There is no build step, no test suite, and no dependencies beyond the `openclaw` CLI.

## Key Commands

```bash
# Install (creates memory files + cron jobs)
bash scripts/install.sh

# Install with options
bash scripts/install.sh --model anthropic/claude-opus-4-6
bash scripts/install.sh --observer-interval "*/30 * * * *"
bash scripts/install.sh --reflector-schedule "0 6 * * *"

# Uninstall
bash scripts/uninstall.sh
bash scripts/uninstall.sh --purge  # also removes memory files

# Manual triggers (requires openclaw CLI)
openclaw cron trigger observer-memory
openclaw cron trigger reflector-memory
openclaw cron list
```

## Architecture

The system has three tiers of memory, each more compressed:

1. **Raw Messages** (real-time, session only) — full conversation
2. **Observations** (`memory/observations.md`, updated every 15 min by Observer) — timestamped, prioritized notes with a "Current Context" block
3. **Reflections** (`memory/reflections.md`, updated daily by Reflector) — stable long-term memory: identity, projects, preferences (target: 200–600 lines)

The Observer and Reflector are **isolated cron agents** — they don't share a session with the main agent. They communicate only through the memory files.

### Observer (`reference/observer-prompt.md`)
- Cron: every 15 minutes (default)
- Reads main session history, compresses unprocessed messages into prioritized observations (🔴 important, 🟡 contextual, 🟢 minor)
- Skips runs with <10 new messages
- Appends to `memory/observations.md`

### Reflector (`reference/reflector-prompt.md`)
- Cron: daily at 04:00 UTC (default)
- Reads observations + existing reflections, merges/promotes/demotes/archives entries
- Overwrites `memory/reflections.md`
- Trims observations older than 7 days

### Install/Uninstall Scripts (`scripts/`)
- Bash scripts that wrap `openclaw cron create/delete` commands
- Idempotent — re-running install removes existing jobs first
- Default workspace: `$OPENCLAW_WORKSPACE` or `~/.openclaw/workspace`

## Editing Guidelines

- When modifying prompts in `reference/`, preserve the priority system (🔴/🟡/🟢) and the output format sections — downstream agents depend on these structures.
- The reflections target size (200–600 lines) and observation retention window (7 days) are defined in the prompts, not in config files.
- `SKILL.md` is the OpenClaw skill integration guide — keep it in sync with README.md when making changes to installation or configuration.
