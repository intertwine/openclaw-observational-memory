#!/usr/bin/env bash
# Observational Memory — Uninstall Script
# Removes Observer and Reflector cron jobs.
#
# Usage:
#   bash scripts/uninstall.sh [options]
#
# Options:
#   --purge     Also remove memory/observations.md and memory/reflections.md
#   --workspace DIR  OpenClaw workspace path (default: $OPENCLAW_WORKSPACE or ~/.openclaw/workspace)
#   --help      Show this help message

set -euo pipefail

PURGE=false
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge)
      PURGE=true; shift ;;
    --workspace)
      WORKSPACE="$2"; shift 2 ;;
    --help|-h)
      head -12 "$0" | tail -10
      exit 0 ;;
    *)
      echo "❌ Unknown option: $1"; exit 1 ;;
  esac
done

if ! command -v openclaw &>/dev/null; then
  echo "❌ 'openclaw' CLI not found in PATH."
  exit 1
fi

echo "🧠 Observational Memory — Uninstaller"
echo "──────────────────────────────────────"
echo ""

# --- Remove cron jobs ---
for job_name in observer-memory reflector-memory; do
  if openclaw cron list 2>/dev/null | grep -q "$job_name"; then
    echo "🗑️  Removing cron job: $job_name"
    openclaw cron delete "$job_name"
    echo "   ✅ Removed"
  else
    echo "⏭️  Cron job '$job_name' not found — skipping"
  fi
done

# --- Optionally purge memory files ---
if [[ "$PURGE" == true ]]; then
  echo ""
  echo "🗑️  Purging memory files..."
  for f in "$WORKSPACE/memory/observations.md" "$WORKSPACE/memory/reflections.md"; do
    if [[ -f "$f" ]]; then
      rm "$f"
      echo "   Removed: $f"
    fi
  done
  echo "   ✅ Memory files purged"
else
  echo ""
  echo "ℹ️  Memory files preserved. Use --purge to remove them."
fi

echo ""
echo "──────────────────────────────────────"
echo "✅ Uninstall complete."
