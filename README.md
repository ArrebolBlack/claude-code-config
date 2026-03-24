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
    ├── bootstrap.sh                 # Linux/macOS new device setup (one command)
    └── sync-mcp.sh                  # Linux/macOS re-apply MCP servers
```

---

## Setup on a New Device

### Linux / macOS

1. Install [Claude Code](https://claude.ai/download)

2. Clone this repo:
   ```bash
   git clone https://github.com/ArrebolBlack/claude-code-config.git ~/claude_code_config
   ```

3. Add your GitHub PAT to your shell profile:
   ```bash
   # bash
   echo "export GITHUB_PAT='ghp_your_token_here'" >> ~/.bashrc && source ~/.bashrc
   # zsh (macOS default)
   echo "export GITHUB_PAT='ghp_your_token_here'" >> ~/.zshrc && source ~/.zshrc
   ```

4. Run bootstrap:
   ```bash
   bash ~/claude_code_config/scripts/bootstrap.sh
   ```

The script handles everything: backup existing files → create symlinks → register MCP servers → install plugins.

---

### Windows

> **Prerequisite:** Run PowerShell as **Administrator** (required for creating symlinks).
> Alternatively, enable Developer Mode (Settings → System → For developers → Developer Mode) to create symlinks without admin rights.

1. Install [Claude Code](https://claude.ai/download) and [Git for Windows](https://git-scm.com/download/win)

2. Open PowerShell as Administrator and clone this repo:
   ```powershell
   git clone https://github.com/ArrebolBlack/claude-code-config.git "$HOME\claude_code_config"
   ```

3. Set your GitHub PAT as a persistent user environment variable:
   ```powershell
   [System.Environment]::SetEnvironmentVariable("GITHUB_PAT", "ghp_your_token_here", "User")
   ```

4. Create symlinks manually (replaces bootstrap.sh):
   ```powershell
   $repo = "$HOME\claude_code_config"
   $claude = "$HOME\.claude"

   # Backup existing files
   if (Test-Path "$claude\settings.json") { Move-Item "$claude\settings.json" "$claude\settings.json.bak" }
   if (Test-Path "$claude\CLAUDE.md")     { Move-Item "$claude\CLAUDE.md"     "$claude\CLAUDE.md.bak"     }
   if (Test-Path "$claude\plugins\known_marketplaces.json") {
       Move-Item "$claude\plugins\known_marketplaces.json" "$claude\plugins\known_marketplaces.json.bak"
   }

   # Create symlinks
   New-Item -ItemType SymbolicLink -Path "$claude\settings.json" -Target "$repo\settings.json"
   New-Item -ItemType SymbolicLink -Path "$claude\CLAUDE.md"     -Target "$repo\CLAUDE.md"
   New-Item -ItemType SymbolicLink -Path "$claude\plugins\known_marketplaces.json" -Target "$repo\plugins\known_marketplaces.json"
   ```

5. Register global MCP servers:
   ```powershell
   claude mcp add playwright -- npx @playwright/mcp@latest
   claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem `
       "$HOME\Documents" "$HOME\Desktop" "$HOME\Downloads"
   ```

6. Install plugins:
   ```powershell
   claude plugins install claude-api@anthropic-agent-skills
   claude plugins install document-skills@anthropic-agent-skills
   claude plugins install example-skills@anthropic-agent-skills
   ```

---

## Syncing Changes

### Linux / macOS
```bash
cd ~/claude_code_config
git pull
# If mcp.json changed, re-apply:
bash scripts/sync-mcp.sh
```

### Windows
```powershell
cd "$HOME\claude_code_config"
git pull
# If mcp.json changed, re-register MCP servers (see step 5 above)
```

---

## What's Tracked vs Excluded

**Tracked (synced across devices):**
- `settings.json` — plugin enablement, marketplace URLs
- `CLAUDE.md` — global instructions
- `mcp.json` — MCP server declarations (no secrets)
- `plugins/known_marketplaces.json` — marketplace registry

**Not tracked (machine-local or contains secrets):**
- `~/.claude.json` / `%USERPROFILE%\.claude.json` — app state DB (sessions, secrets, project state)
- `~/.claude/plugins/installed_plugins.json` — absolute install paths
- `~/.claude/plugins/cache/` — downloaded plugin binaries
- `~/.claude/projects/`, `sessions/`, `telemetry/` — runtime state

---

## Secrets

GitHub PAT and other secrets are **never committed**.

**Linux / macOS** — store in your shell profile:
```bash
export GITHUB_PAT='ghp_your_token_here'
```

**Windows** — store as a user environment variable:
```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_PAT", "ghp_your_token_here", "User")
```

For project-level MCP servers (e.g. github-server), run from within the project directory:

**Linux / macOS:**
```bash
GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```

**Windows:**
```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = $env:GITHUB_PAT
claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```
