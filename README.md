# Claude Code Config

[中文](./README.zh.md) | **English**

Cross-device Claude Code configuration managed via git.

## Structure

```
claude_code_config/
├── settings.json                    # Plugin enablement & marketplace URLs
├── CLAUDE.md                        # Global instructions for Claude Code
├── mcp.json                         # Portable MCP server declarations (no secrets)
├── plugins/
│   └── known_marketplaces.json      # Marketplace registry
└── scripts/
    ├── bootstrap.sh                 # New device setup (one command)
    └── sync-mcp.sh                  # Re-apply MCP servers
```

## Setup on a New Device

1. Install [Claude Code](https://claude.ai/download)

2. Clone this repo:
   ```bash
   git clone https://github.com/ArrebolBlack/claude-code-config.git ~/claude_code_config
   ```

3. Add your GitHub PAT to your shell profile:
   ```bash
   echo "export GITHUB_PAT='ghp_your_token_here'" >> ~/.bashrc
   source ~/.bashrc
   ```

4. Run bootstrap:
   ```bash
   bash ~/claude_code_config/scripts/bootstrap.sh
   ```

## Syncing Changes

After pulling updates from another device:
```bash
git pull
# settings.json changes take effect immediately via symlink
# If mcp.json changed, re-apply:
bash scripts/sync-mcp.sh
```

## What's Tracked vs Excluded

**Tracked (synced across devices):**
- `settings.json` — plugin enablement, marketplace URLs
- `CLAUDE.md` — global instructions
- `mcp.json` — MCP server declarations (no secrets)
- `plugins/known_marketplaces.json` — marketplace registry

**Not tracked (machine-local or contains secrets):**
- `~/.claude.json` — app state DB (sessions, secrets, project state)
- `~/.claude/plugins/installed_plugins.json` — absolute install paths
- `~/.claude/plugins/cache/` — downloaded plugin binaries
- `~/.claude/projects/`, `sessions/`, `telemetry/` — runtime state

## Secrets

GitHub PAT and other secrets are **never committed**. Store them in your shell profile:
```bash
export GITHUB_PAT='ghp_your_token_here'
```

For project-level MCP servers (e.g. github-server), run from within the project directory:
```bash
GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```
