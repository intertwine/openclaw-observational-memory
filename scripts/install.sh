#!/usr/bin/env bash
# Observational Memory — Install Script
# Sets up Observer and Reflector cron jobs in OpenClaw.
#
# Usage:
#   bash scripts/install.sh [options]
#
# Options:
#   --model MODEL              LLM model to use (default: anthropic/claude-sonnet-4-20250514)
#   --observer-interval CRON   Observer schedule (default: "*/15 * * * *")
#   --reflector-schedule CRON  Reflector schedule (default: "0 4 * * *")
#   --workspace DIR            OpenClaw workspace path (default: $OPENCLAW_WORKSPACE or ~/.openclaw/workspace)
#   --help                     Show this help message

set -euo pipefail

# --- Defaults ---
MODEL="anthropic/claude-sonnet-4-20250514"
OBSERVER_INTERVAL="*/15 * * * *"
REFLECTOR_SCHEDULE="0 4 * * *"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      MODEL="$2"; shift 2 ;;
    --observer-interval)
      OBSERVER_INTERVAL="$2"; shift 2 ;;
    --reflector-schedule)
      REFLECTOR_SCHEDULE="$2"; shift 2 ;;
    --workspace)
      WORKSPACE="$2"; shift 2 ;;
    --help|-h)
      head -14 "$0" | tail -12
      exit 0 ;;
    *)
      echo "❌ Unknown option: $1"
      echo "   Run with --help for usage."
      exit 1 ;;
  esac
done

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OBSERVER_PROMPT="$REPO_DIR/reference/observer-prompt.md"
REFLECTOR_PROMPT="$REPO_DIR/reference/reflector-prompt.md"

# --- Preflight checks ---
if ! command -v openclaw &>/dev/null; then
  echo "❌ 'openclaw' CLI not found in PATH."
  echo "   Install OpenClaw first: https://openclaw.ai"
  exit 1
fi

if [[ ! -f "$OBSERVER_PROMPT" ]]; then
  echo "❌ Observer prompt not found at: $OBSERVER_PROMPT"
  echo "   Make sure you're running this from the repo directory."
  exit 1
fi

echo "🧠 Observational Memory — Installer"
echo "──────────────────────────────────────"
echo "  Workspace:  $WORKSPACE"
echo "  Model:      $MODEL"
echo "  Observer:   $OBSERVER_INTERVAL"
echo "  Reflector:  $REFLECTOR_SCHEDULE"
echo ""

# --- Create memory files ---
mkdir -p "$WORKSPACE/memory"

if [[ ! -f "$WORKSPACE/memory/observations.md" ]]; then
  cat > "$WORKSPACE/memory/observations.md" << 'EOF'
# Observations

<!-- Maintained by the Observer agent. Do not edit manually unless needed. -->
EOF
  echo "✅ Created memory/observations.md"
else
  echo "⏭️  memory/observations.md already exists — skipping"
fi

if [[ ! -f "$WORKSPACE/memory/reflections.md" ]]; then
  cat > "$WORKSPACE/memory/reflections.md" << 'EOF'
# Reflections — Long-Term Memory

*Last updated: never*

<!-- Maintained by the Reflector agent. Do not edit manually unless needed. -->

## Core Identity

## Active Projects

## Preferences & Opinions

## Relationship & Communication

## Key Facts & Context

## Recent Themes

## Archive
EOF
  echo "✅ Created memory/reflections.md"
else
  echo "⏭️  memory/reflections.md already exists — skipping"
fi

echo ""

# --- Create cron jobs ---
echo "📅 Creating cron jobs..."
echo ""

# Remove existing jobs with same names (idempotent install)
for job_name in observer-memory reflector-memory; do
  if openclaw cron list 2>/dev/null | grep -q "$job_name"; then
    echo "   Removing existing '$job_name' job..."
    openclaw cron delete "$job_name" 2>/dev/null || true
  fi
done

echo "   Creating observer-memory cron job..."
openclaw cron create \
  --name observer-memory \
  --schedule "$OBSERVER_INTERVAL" \
  --prompt-file "$OBSERVER_PROMPT" \
  --model "$MODEL" \
  --description "Observational Memory: compress recent conversation into observations"

echo "   ✅ observer-memory created (schedule: $OBSERVER_INTERVAL)"

echo ""
echo "   Creating reflector-memory cron job..."
openclaw cron create \
  --name reflector-memory \
  --schedule "$REFLECTOR_SCHEDULE" \
  --prompt-file "$REFLECTOR_PROMPT" \
  --model "$MODEL" \
  --description "Observational Memory: condense observations into long-term reflections"

echo "   ✅ reflector-memory created (schedule: $REFLECTOR_SCHEDULE)"

echo ""
echo "──────────────────────────────────────"
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Add observation/reflection loading to your AGENTS.md"
echo "     (see SKILL.md for the exact lines to add)"
echo ""
echo "  2. Verify cron jobs are running:"
echo "     openclaw cron list"
echo ""
echo "  3. Trigger a manual run to test:"
echo "     openclaw cron trigger observer-memory"
echo ""
echo "  To uninstall: bash $SCRIPT_DIR/uninstall.sh"
