#!/usr/bin/env bash
# sync-mcp.sh — Apply global MCP servers from mcp.json to Claude Code app state
# Usage: bash sync-mcp.sh [--with-project-servers]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "--- Syncing global MCP servers ---"

# Apply playwright
if claude mcp list 2>/dev/null | grep -q "^playwright"; then
  echo "  playwright: already registered (skipping)"
else
  claude mcp add playwright -- npx @playwright/mcp@latest
  echo "  playwright: added"
fi

# Apply filesystem (using $HOME so it expands to current device's home)
if claude mcp list 2>/dev/null | grep -q "^filesystem"; then
  echo "  filesystem: already registered (skipping)"
else
  claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \
    "$HOME/Documents" "$HOME/Desktop" "$HOME/Downloads"
  echo "  filesystem: added"
fi

echo "Global MCP servers applied."
echo ""

# Optional: project-level servers with secrets
if [[ "${1:-}" == "--with-project-servers" ]]; then
  if [[ -z "${GITHUB_PAT:-}" ]]; then
    echo "ERROR: GITHUB_PAT env var not set. Skipping project-level github-server."
    echo "  Set it in ~/.bashrc: export GITHUB_PAT='ghp_your_token_here'"
    exit 1
  fi
  echo "--- Project-level MCP servers ---"
  echo "  Run the following from within your project directory:"
  echo ""
  echo "  GITHUB_PERSONAL_ACCESS_TOKEN=\$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github"
  echo ""
  echo "  (The actual token is read from your GITHUB_PAT env var at runtime, not stored in this file)"
fi
