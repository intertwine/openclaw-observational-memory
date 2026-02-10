#!/usr/bin/env bash
set -euo pipefail

# enable-qmd.sh — Enable or disable QMD hybrid search for Observational Memory
#
# Usage:
#   bash scripts/enable-qmd.sh            # Enable QMD backend
#   bash scripts/enable-qmd.sh --disable  # Revert to default memory backend
#   bash scripts/enable-qmd.sh --help     # Show this help

DISABLE=false

for arg in "$@"; do
  case "$arg" in
    --disable) DISABLE=true ;;
    --help|-h)
      sed -n '3,7p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# --- Disable mode ---
if [ "$DISABLE" = true ]; then
  echo "🔄 Disabling QMD memory backend..."
  if command -v openclaw &>/dev/null; then
    openclaw config patch '{"memory": {"backend": "default"}}' 2>/dev/null && {
      echo "✅ Memory backend reverted to default."
      exit 0
    }
  fi
  echo ""
  echo "Could not auto-patch config. Manually set in your OpenClaw config:"
  echo '  "memory": { "backend": "default" }'
  exit 0
fi

# --- Enable mode ---
echo "🧠 Enabling QMD hybrid search for Observational Memory"
echo ""

# Check for bun
if ! command -v bun &>/dev/null; then
  echo "❌ bun is not installed. QMD requires bun to run."
  echo ""
  echo "Install bun:"
  echo "  curl -fsSL https://bun.sh/install | bash"
  echo ""
  echo "Then re-run this script."
  exit 1
fi
echo "✅ bun found: $(bun --version)"

# Check for / install qmd
if ! command -v qmd &>/dev/null; then
  echo "📦 Installing qmd..."
  bun install -g qmd
  if ! command -v qmd &>/dev/null; then
    echo "❌ qmd installation failed. Try manually: bun install -g qmd"
    exit 1
  fi
fi
echo "✅ qmd found: $(qmd --version 2>/dev/null || echo 'installed')"

# Apply OpenClaw config patch
CONFIG_PATCH='{
  "memory": {
    "backend": "qmd",
    "citations": "auto",
    "qmd": {
      "includeDefaultMemory": true,
      "update": { "interval": "5m", "debounceMs": 15000 },
      "limits": { "maxResults": 6, "timeoutMs": 8000 },
      "scope": {
        "default": "deny",
        "rules": [{"action": "allow", "match": {"chatType": "direct"}}]
      }
    }
  }
}'

echo ""
echo "📝 Applying OpenClaw config patch..."
if command -v openclaw &>/dev/null; then
  openclaw config patch "$CONFIG_PATCH" 2>/dev/null && {
    echo "✅ Config patch applied."
  } || {
    echo "⚠️  Could not auto-patch config. Add this to your OpenClaw config manually:"
    echo ""
    echo "$CONFIG_PATCH"
  }
else
  echo "⚠️  openclaw CLI not found. Add this to your OpenClaw config manually:"
  echo ""
  echo "$CONFIG_PATCH"
fi

# Warm the index
echo ""
echo "🔍 Building QMD search index..."

if qmd update 2>/dev/null; then
  echo "✅ BM25 index built."
else
  echo "⚠️  qmd update failed — you may need to run it manually after setup."
fi

echo "🧮 Generating embeddings (this may take a moment)..."
if qmd embed 2>/dev/null; then
  echo "✅ Embeddings generated."
else
  echo ""
  echo "⚠️  Embedding generation failed. This usually means:"
  echo "   - Not enough RAM for local GGUF models (~2 GB needed)"
  echo "   - Missing model files (first run downloads them)"
  echo ""
  echo "   Don't worry — BM25 keyword search still works, and vectors will"
  echo "   fall back to OpenAI API embeddings if OPENAI_API_KEY is set."
fi

echo ""
echo "🎉 QMD is enabled! Your agent will now use hybrid search for memory retrieval."
echo "   To disable: bash scripts/enable-qmd.sh --disable"
