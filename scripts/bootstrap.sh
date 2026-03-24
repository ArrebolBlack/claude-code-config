#!/usr/bin/env bash
# bootstrap.sh — One-command setup for Claude Code config on a new device
# Usage: bash bootstrap.sh
#
# Prerequisites:
#   1. Claude Code must be installed (https://claude.ai/download)
#   2. Set secrets in your shell profile BEFORE running this script:
#      export GITHUB_PAT='ghp_your_token_here'

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Config Bootstrap ==="
echo "Repo:        $REPO_DIR"
echo "Claude dir:  $CLAUDE_DIR"
echo ""

# ── 1. Verify Claude Code is installed ────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' not found. Install Claude Code first:"
  echo "  https://claude.ai/download"
  exit 1
fi

# ── 2. Helper: backup existing files before symlinking ────────────────────────
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "  Backing up: $target -> $backup"
    mv "$target" "$backup"
  fi
}

# ── 3. Create symlinks ─────────────────────────────────────────────────────────
echo "--- Creating symlinks ---"

mkdir -p "$CLAUDE_DIR/plugins"

# settings.json
backup_if_exists "$CLAUDE_DIR/settings.json"
ln -sf "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked: ~/.claude/settings.json"

# CLAUDE.md
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
ln -sf "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Linked: ~/.claude/CLAUDE.md"

# plugins/known_marketplaces.json
backup_if_exists "$CLAUDE_DIR/plugins/known_marketplaces.json"
ln -sf "$REPO_DIR/plugins/known_marketplaces.json" "$CLAUDE_DIR/plugins/known_marketplaces.json"
echo "  Linked: ~/.claude/plugins/known_marketplaces.json"

echo ""

# ── 4. Apply global MCP servers ───────────────────────────────────────────────
echo "--- Applying global MCP servers ---"
bash "$REPO_DIR/scripts/sync-mcp.sh"
echo ""

# ── 5. Install plugins declared in settings.json ──────────────────────────────
echo "--- Installing plugins ---"
claude plugins install claude-api@anthropic-agent-skills 2>/dev/null && \
  echo "  claude-api: installed" || echo "  claude-api: already installed or skipped"
claude plugins install document-skills@anthropic-agent-skills 2>/dev/null && \
  echo "  document-skills: installed" || echo "  document-skills: already installed or skipped"
claude plugins install example-skills@anthropic-agent-skills 2>/dev/null && \
  echo "  example-skills: installed" || echo "  example-skills: already installed or skipped"
echo ""

# ── 6. Remind about secrets ───────────────────────────────────────────────────
echo "=== MANUAL STEPS REQUIRED ==="
echo ""
echo "1. Add your GitHub PAT to your shell profile (if not done already):"
echo "   echo \"export GITHUB_PAT='ghp_your_token_here'\" >> ~/.bashrc"
echo "   source ~/.bashrc"
echo ""
echo "2. To add the github-server MCP to a specific project, run from that project dir:"
echo "   GITHUB_PERSONAL_ACCESS_TOKEN=\$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github"
echo ""
echo "=== Bootstrap complete! ==="
echo "Start Claude Code and verify everything works."
