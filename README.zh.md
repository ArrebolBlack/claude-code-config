# Claude Code 配置

**中文** | [English](./README.md)

通过 git 管理的跨设备 Claude Code 配置。

## 目录结构

```
claude_code_config/
├── settings.json                    # 插件启用状态、Marketplace URL、SessionStart hook
├── CLAUDE.md                        # Claude Code 全局指令
├── mcp.json                         # 可移植的 MCP 服务器声明（不含密钥）
├── providers.example.json           # API provider 模板（入库）
├── providers.local.json             # API provider 实际密钥（.gitignore 排除）
├── .current-provider                # 当前激活的 provider 名（入库）
├── plugins/
│   └── known_marketplaces.json      # Marketplace 注册表
└── scripts/
    ├── bootstrap.sh                 # Linux/macOS 新设备一键初始化
    ├── sync-mcp.sh                  # Linux/macOS 重新应用 MCP 服务器配置
    ├── inject-provider.sh           # SessionStart hook：自动注入 API 凭据
    └── use-api.sh                   # 切换 API provider
```

---

## 新设备初始化

### Linux / macOS

1. 安装 [Claude Code](https://claude.ai/download)

2. Clone 本仓库：
   ```bash
   git clone https://github.com/ArrebolBlack/claude-code-config.git ~/claude_code_config
   ```

3. 在 shell profile 中设置密钥（如需要 github-server MCP）：
   ```bash
   # bash 用户
   echo "export GITHUB_PAT='ghp_你的token'" >> ~/.bashrc && source ~/.bashrc
   # zsh 用户（macOS 默认）
   echo "export GITHUB_PAT='ghp_你的token'" >> ~/.zshrc && source ~/.zshrc
   ```

4. 运行 bootstrap 脚本：
   ```bash
   bash ~/claude_code_config/scripts/bootstrap.sh
   ```

脚本会自动完成：备份原文件 → 创建软链接 → 注册 MCP 服务器 → 安装插件 → 配置 API provider 切换。

---

## API Provider 切换

支持管理多个 API provider（不同厂商的 base URL + API key），随时切换。

### 配置 providers.local.json

bootstrap 脚本会自动从模板创建 `providers.local.json`，填入你的真实密钥：

```json
{
  "anthropic": {
    "base_url": "https://api.anthropic.com",
    "api_key": "sk-ant-your-key-here",
    "auth_token": ""
  },
  "glm": {
    "base_url": "https://open.bigmodel.cn/api/anthropic",
    "api_key": "",
    "auth_token": "your-zhipu-token.here"
  }
}
```

每个 provider 必须包含三个字段：`base_url`、`api_key`、`auth_token`。对于不需要某个字段的 provider，可以留空或设置为空字符串。

> `providers.local.json` 已加入 `.gitignore`，不会被推送到 GitHub。

### 使用方式

```bash
# 查看可用 providers 及当前激活的
use-api

# 切换 provider（下次启动新 claude 会话自动生效）
use-api openai

# 在当前 shell 立即生效（需要重启 claude）
eval "$(use-api openai --export)"
```

### 工作原理

- `settings.json` 中注册了 `SessionStart` hook，每次启动新 claude 会话时自动读取 `.current-provider` 并注入对应的 `ANTHROPIC_BASE_URL`、`ANTHROPIC_API_KEY` 和 `ANTHROPIC_AUTH_TOKEN`
- 每个 provider 的三个字段（`base_url`、`api_key`、`auth_token`）都会被独立读取并设置
- 由于 Claude Code 在启动时读取一次 API 配置，切换后需要开启新会话才能生效
- `eval "$(use-api <name> --export)"` 可同时更新当前 shell 的环境变量，然后重启 claude 即可立即使用新 provider

---

### Windows

> **前提：** 需要以**管理员身份**运行 PowerShell（创建符号链接需要管理员权限）。
> 也可以开启开发者模式（Settings → System → For developers → Developer Mode），开启后无需管理员权限即可创建符号链接。

1. 安装 [Claude Code](https://claude.ai/download)，并安装 [Git for Windows](https://git-scm.com/download/win)

2. 以管理员身份打开 PowerShell，Clone 本仓库：
   ```powershell
   git clone https://github.com/ArrebolBlack/claude-code-config.git "$HOME\claude_code_config"
   ```

3. 设置密钥环境变量（永久生效）：
   ```powershell
   [System.Environment]::SetEnvironmentVariable("GITHUB_PAT", "ghp_你的token", "User")
   ```

4. 手动创建符号链接（替代 bootstrap.sh）：
   ```powershell
   $repo = "$HOME\claude_code_config"
   $claude = "$HOME\.claude"

   # 备份原文件
   if (Test-Path "$claude\settings.json") { Move-Item "$claude\settings.json" "$claude\settings.json.bak" }
   if (Test-Path "$claude\CLAUDE.md")     { Move-Item "$claude\CLAUDE.md"     "$claude\CLAUDE.md.bak"     }
   if (Test-Path "$claude\plugins\known_marketplaces.json") {
       Move-Item "$claude\plugins\known_marketplaces.json" "$claude\plugins\known_marketplaces.json.bak"
   }

   # 创建符号链接
   New-Item -ItemType SymbolicLink -Path "$claude\settings.json" -Target "$repo\settings.json"
   New-Item -ItemType SymbolicLink -Path "$claude\CLAUDE.md"     -Target "$repo\CLAUDE.md"
   New-Item -ItemType SymbolicLink -Path "$claude\plugins\known_marketplaces.json" -Target "$repo\plugins\known_marketplaces.json"
   ```

5. 注册全局 MCP 服务器：
   ```powershell
   claude mcp add playwright -- npx @playwright/mcp@latest
   claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem `
       "$HOME\Documents" "$HOME\Desktop" "$HOME\Downloads"
   ```

6. 安装插件：
   ```powershell
   claude plugins install claude-api@anthropic-agent-skills
   claude plugins install document-skills@anthropic-agent-skills
   claude plugins install example-skills@anthropic-agent-skills
   ```

---

## 同步配置

### Linux / macOS
```bash
cd ~/claude_code_config
git pull
# 如果 mcp.json 有变更，重新应用：
bash scripts/sync-mcp.sh
```

### Windows
```powershell
cd "$HOME\claude_code_config"
git pull
# 如果 mcp.json 有变更，重新注册 MCP 服务器（参考上方步骤 5）
```

---

## 跟踪 vs 排除的文件

**跟踪（跨设备同步）：**
- `settings.json` — 插件启用状态、Marketplace URL、SessionStart hook
- `CLAUDE.md` — 全局指令
- `mcp.json` — MCP 服务器声明（不含密钥）
- `plugins/known_marketplaces.json` — Marketplace 注册表
- `providers.example.json` — API provider 模板
- `.current-provider` — 当前激活的 provider 名

**不跟踪（机器本地或含密钥）：**
- `providers.local.json` — API provider 实际密钥
- `~/.claude.json` / `%USERPROFILE%\.claude.json` — 应用状态数据库（会话、密钥、项目状态）
- `~/.claude/plugins/installed_plugins.json` — 绝对安装路径
- `~/.claude/plugins/cache/` — 已下载的插件文件
- `~/.claude/projects/`、`sessions/`、`telemetry/` — 运行时状态

---

## 密钥管理

GitHub PAT 等密钥**绝不入库**。

**Linux / macOS** — 存储在 shell profile：
```bash
export GITHUB_PAT='ghp_你的token'
```

**Windows** — 存储为用户级环境变量：
```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_PAT", "ghp_你的token", "User")
```

项目级 MCP 服务器（如 github-server），在项目目录下运行：

**Linux / macOS：**
```bash
GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```

**Windows：**
```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = $env:GITHUB_PAT
claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```
