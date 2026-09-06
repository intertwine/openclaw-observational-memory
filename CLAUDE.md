# CLAUDE.md

## What This Is

A two-tier compressed memory system for AI coding agents. Two background agents (Observer + Reflector) compress raw conversation history into dense memory files that an agent reads on startup.

This repo contains **reference prompts** and **OpenClaw integration scripts**. It is not a standalone application — it's a set of prompt files (`reference/`), shell scripts (`scripts/`), and documentation. There is no build step, no test suite, and no dependencies beyond the `openclaw` CLI.

A companion Python package ([`observational-memory`](https://github.com/intertwine/observational-memory)) provides a standalone CLI (`om`) with the same Observer/Reflector logic plus transcript parsing, backfill, search, and session hooks for Claude Code and Codex.

## Key Commands

```bash
# Install (creates memory files + cron jobs)
bash scripts/install.sh

# Install with options (`bash scripts/install.sh --help` lists them all)
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

Three tiers, each more compressed than the last: raw session messages → `memory/observations.md` (written by the Observer, every 15 minutes by default: timestamped notes with 🔴/🟡/🟢 priorities plus a "Current Context" block) → `memory/reflections.md` (written by the Reflector, daily: stable identity, projects, and preferences, updated incrementally from the `Last reflected` timestamp onward).

- The Observer and Reflector are isolated OpenClaw cron agents. They never share a session with the main agent and communicate only through the memory files.
- Their behavior (skip threshold, priority system, 7-day observation trim, reflections size target) lives in `reference/observer-prompt.md` and `reference/reflector-prompt.md`, not in config files.
- `scripts/install.sh` and `scripts/uninstall.sh` wrap `openclaw cron create/delete`. Install is idempotent (it removes existing jobs first); the workspace defaults to `$OPENCLAW_WORKSPACE` or `~/.openclaw/workspace`.

## Editing Guidelines

- When modifying prompts in `reference/`, preserve the priority system (🔴/🟡/🟢) and the output format sections — downstream agents depend on these structures.
- The reflections target size (200–600 lines) and observation retention window (7 days) are defined in the prompts, not in config files.
- The `Last reflected` timestamp in reflections.md controls incremental processing — the Reflector only reads observations from that date onward.
- The Observer's "Never Log" list (heartbeats, cron notifications, system messages) prevents noise from polluting observations.
- `SKILL.md` is the OpenClaw skill integration guide — keep it in sync with README.md when making changes to installation or configuration.
