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

# ── 6. Set up API provider switching ──────────────────────────────────────────
echo "--- Setting up API provider switching ---"

# Patch the inject-provider.sh path in settings.json to match this machine's repo location
SETTINGS="$REPO_DIR/settings.json"
INJECT_SCRIPT="$REPO_DIR/scripts/inject-provider.sh"
# Replace any existing inject-provider.sh path with the current one
python3 -c "
import json, re
with open('$SETTINGS') as f:
    content = f.read()
# Replace the command path for inject-provider.sh
content = re.sub(
    r'\"command\": \"bash .+/inject-provider\.sh\"',
    '\"command\": \"bash $INJECT_SCRIPT\"',
    content
)
with open('$SETTINGS', 'w') as f:
    f.write(content)
print('  Hook path updated in settings.json')
"

# Set up providers.local.json if not present
if [[ ! -f "$REPO_DIR/providers.local.json" ]]; then
  cp "$REPO_DIR/providers.example.json" "$REPO_DIR/providers.local.json"
  echo "  Created providers.local.json from template"
  echo "  IMPORTANT: Edit $REPO_DIR/providers.local.json and fill in your real API keys!"
else
  echo "  providers.local.json already exists"
fi

# Add use-api to PATH via shell profile
SHELL_PROFILE="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_PROFILE="$HOME/.zshrc"
USE_API_ALIAS="alias use-api='bash $REPO_DIR/scripts/use-api.sh'"
if ! grep -qF "use-api.sh" "$SHELL_PROFILE" 2>/dev/null; then
  echo "" >> "$SHELL_PROFILE"
  echo "# Claude Code API provider switching" >> "$SHELL_PROFILE"
  echo "$USE_API_ALIAS" >> "$SHELL_PROFILE"
  echo "  Added 'use-api' alias to $SHELL_PROFILE"
  echo "  Run: source $SHELL_PROFILE"
else
  echo "  'use-api' alias already in $SHELL_PROFILE"
fi
echo ""

# ── 7. Remind about secrets ───────────────────────────────────────────────────
echo "=== MANUAL STEPS REQUIRED ==="
echo ""
echo "1. Fill in your API keys:"
echo "   \$EDITOR $REPO_DIR/providers.local.json"
echo ""
echo "2. Reload your shell profile:"
echo "   source $SHELL_PROFILE"
echo ""
echo "3. Add your GitHub PAT (if using github-server MCP):"
echo "   echo \"export GITHUB_PAT='ghp_your_token_here'\" >> $SHELL_PROFILE"
echo ""
echo "4. To add the github-server MCP to a specific project, run from that project dir:"
echo "   GITHUB_PERSONAL_ACCESS_TOKEN=\$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github"
echo ""
echo "=== Bootstrap complete! ==="
echo "Usage: use-api [provider]   # list or switch API provider"
echo "Start Claude Code and verify everything works."
