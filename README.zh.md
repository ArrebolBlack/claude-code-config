# Claude Code 配置

**中文** | [English](./README.md)

通过 git 管理的跨设备 Claude Code 配置。

## 目录结构

```
claude_code_config/
├── settings.json                    # 插件启用状态与 Marketplace URL
├── CLAUDE.md                        # Claude Code 全局指令
├── mcp.json                         # 可移植的 MCP 服务器声明（不含密钥）
├── plugins/
│   └── known_marketplaces.json      # Marketplace 注册表
└── scripts/
    ├── bootstrap.sh                 # 新设备一键初始化
    └── sync-mcp.sh                  # 重新应用 MCP 服务器配置
```

## 新设备初始化

1. 安装 [Claude Code](https://claude.ai/download)

2. Clone 本仓库：
   ```bash
   git clone https://github.com/ArrebolBlack/claude-code-config.git ~/claude_code_config
   ```

3. 在 shell profile 中设置密钥（如需要 github-server MCP）：
   ```bash
   echo "export GITHUB_PAT='ghp_你的token'" >> ~/.bashrc
   source ~/.bashrc
   ```

4. 运行 bootstrap 脚本：
   ```bash
   bash ~/claude_code_config/scripts/bootstrap.sh
   ```

脚本会自动完成：备份原文件 → 创建软链接 → 注册 MCP 服务器 → 安装插件。

## 同步配置

在其他设备拉取更新后：
```bash
git pull
# settings.json 通过软链接立即生效
# 如果 mcp.json 有变更，重新应用：
bash scripts/sync-mcp.sh
```

## 跟踪 vs 排除的文件

**跟踪（跨设备同步）：**
- `settings.json` — 插件启用状态、Marketplace URL
- `CLAUDE.md` — 全局指令
- `mcp.json` — MCP 服务器声明（不含密钥）
- `plugins/known_marketplaces.json` — Marketplace 注册表

**不跟踪（机器本地或含密钥）：**
- `~/.claude.json` — 应用状态数据库（会话、密钥、项目状态）
- `~/.claude/plugins/installed_plugins.json` — 绝对安装路径
- `~/.claude/plugins/cache/` — 已下载的插件文件
- `~/.claude/projects/`、`sessions/`、`telemetry/` — 运行时状态

## 密钥管理

GitHub PAT 等密钥**绝不入库**，存储在各设备的 shell profile 中：
```bash
export GITHUB_PAT='ghp_你的token'
```

项目级 MCP 服务器（如 github-server），在项目目录下运行：
```bash
GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT claude mcp add --project github-server -- npx @modelcontextprotocol/server-github
```
