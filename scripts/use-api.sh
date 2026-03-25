#!/usr/bin/env bash
# use-api.sh — Switch the active API provider for Claude Code
#
# Usage:
#   use-api                    # List available providers
#   use-api <name>             # Switch provider (next session picks it up automatically)
#   use-api <name> --export    # Print export commands for current shell (use with eval)
#
# Examples:
#   use-api openai
#   eval "$(use-api openai --export)"   # Apply immediately in current shell

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL="$REPO_DIR/providers.local.json"
PROVIDER_FILE="$REPO_DIR/.current-provider"

if [[ ! -f "$LOCAL" ]]; then
  echo "ERROR: providers.local.json not found."
  echo "  Copy the template and fill in your keys:"
  echo "  cp $REPO_DIR/providers.example.json $LOCAL"
  exit 1
fi

PROVIDER="${1:-}"
EXPORT_MODE="${2:-}"

# ── No args: list providers ────────────────────────────────────────────────────
if [[ -z "$PROVIDER" ]]; then
  CURRENT=$(tr -d '[:space:]' < "$PROVIDER_FILE" 2>/dev/null || echo "")
  echo "Available providers (current: ${CURRENT:-none}):"
  python3 -c "
import json
d = json.load(open('$LOCAL'))
for k, v in d.items():
    print(f'  - {k}  ({v[\"base_url\"]})')
"
  exit 0
fi

# ── Validate provider exists ───────────────────────────────────────────────────
python3 -c "
import json, sys
d = json.load(open('$LOCAL'))
if '$PROVIDER' not in d:
    print(f\"Error: provider '$PROVIDER' not found in providers.local.json\")
    print('Available:', ', '.join(d.keys()))
    sys.exit(1)
" || exit 1

# ── Switch provider ────────────────────────────────────────────────────────────
echo "$PROVIDER" > "$PROVIDER_FILE"

API_KEY=$(python3 -c "import json; d=json.load(open('$LOCAL')); print(d['$PROVIDER']['api_key'])")
BASE_URL=$(python3 -c "import json; d=json.load(open('$LOCAL')); print(d['$PROVIDER']['base_url'])")

# --export mode: print eval-able export commands
if [[ "$EXPORT_MODE" == "--export" ]]; then
  echo "export ANTHROPIC_API_KEY='$API_KEY'"
  echo "export ANTHROPIC_BASE_URL='$BASE_URL'"
  exit 0
fi

echo "Switched to: $PROVIDER"
echo "  base_url: $BASE_URL"
echo ""
echo "Next new claude session will use this provider automatically."
echo ""
echo "To apply in the CURRENT shell immediately:"
echo "  eval \"\$(use-api $PROVIDER --export)\""
echo "Then restart claude."
