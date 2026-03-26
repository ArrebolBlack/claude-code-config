#!/usr/bin/env bash
# inject-provider.sh — SessionStart hook: inject API credentials from providers.local.json
# Called automatically by Claude Code on each new session via hooks in settings.json.
# Do NOT call this script manually.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROVIDER_FILE="$REPO_DIR/.current-provider"
LOCAL="$REPO_DIR/providers.local.json"

# Silently exit if not configured
[[ -f "$PROVIDER_FILE" ]] || exit 0
[[ -f "$LOCAL" ]] || exit 0
[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0

PROVIDER=$(tr -d '[:space:]' < "$PROVIDER_FILE")
[[ -n "$PROVIDER" ]] || exit 0

BASE_URL=$(python3 -c "
import json, sys
d = json.load(open('$LOCAL'))
if '$PROVIDER' not in d:
    sys.exit(1)
print(d['$PROVIDER'].get('base_url', ''))
" 2>/dev/null) || exit 0

API_KEY=$(python3 -c "
import json, sys
d = json.load(open('$LOCAL'))
if '$PROVIDER' not in d:
    sys.exit(1)
print(d['$PROVIDER'].get('api_key', ''))
" 2>/dev/null) || exit 0

AUTH_TOKEN=$(python3 -c "
import json, sys
d = json.load(open('$LOCAL'))
if '$PROVIDER' not in d:
    sys.exit(1)
print(d['$PROVIDER'].get('auth_token', ''))
" 2>/dev/null) || exit 0

# Intelligent environment variable selection based on provider type
case "$PROVIDER" in
    "glm"|"zhipu"|"bigmodel")
        # ZHIPU/GLM providers use ANTHROPIC_AUTH_TOKEN only
        [[ -n "$BASE_URL" ]]   && echo "ANTHROPIC_BASE_URL=$BASE_URL"   >> "$CLAUDE_ENV_FILE"
        [[ -n "$AUTH_TOKEN" ]] && echo "ANTHROPIC_AUTH_TOKEN=$AUTH_TOKEN" >> "$CLAUDE_ENV_FILE"
        ;;
    *)
        # Other providers use ANTHROPIC_API_KEY
        [[ -n "$BASE_URL" ]] && echo "ANTHROPIC_BASE_URL=$BASE_URL" >> "$CLAUDE_ENV_FILE"
        [[ -n "$API_KEY" ]]  && echo "ANTHROPIC_API_KEY=$API_KEY"     >> "$CLAUDE_ENV_FILE"
        ;;
esac
