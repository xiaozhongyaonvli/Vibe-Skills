# 手动复制安装（离线 / 无管理员权限）

如果你不想跑安装脚本，只想手动放文件，这条路径只解决“把仓库文件复制到目标宿主根目录”。

当前公开支持六个宿主：

- `codex`
- `claude-code`
- `cursor`
- `windsurf`
- `openclaw`
- `opencode`

## 基本复制内容

复制到目标根目录：

- `skills/`
- `commands/`
- `config/upstream-lock.json`
- `skills/vibe/`

## 宿主根目录提示

- `codex` -> `CODEX_HOME` 或 `~/.vibeskills/targets/codex`
- `claude-code` -> `CLAUDE_HOME` 或 `~/.vibeskills/targets/claude-code`
- `cursor` -> `CURSOR_HOME` 或 `~/.vibeskills/targets/cursor`
- `windsurf` -> `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf`
- `openclaw` -> `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw`
- `opencode` -> `OPENCODE_HOME` 或 `~/.vibeskills/targets/opencode`

如果目标是 `windsurf`，还要额外注意：

- 如需与当前脚本安装结果严格对齐，优先重新运行 `install.* --host windsurf`
- 当前公开合同下，宿主侧 sidecar 以 `.vibeskills/host-settings.json` 与 `.vibeskills/host-closure.json` 为准，而不是 `mcp_config.json` / `global_workflows/`

如果目标是 `opencode`，请改用 OpenCode 预览载荷：

- `skills/`
- `.vibeskills/host-settings.json`
- `.vibeskills/host-closure.json`
- `.vibeskills/install-ledger.json`
- `.vibeskills/bin/*-specialist-wrapper.*`
- `opencode.json.example`

并结合 [`opencode-path.md`](./opencode-path.md) 处理 preview adapter 的后续步骤。

## 复制后仍需你自己完成的部分

### Codex

- 维护 `~/.codex/settings.json`
- 直接编辑顶层 `env` 对象，不要再额外造一个自定义 secrets 块
- 如需 AI 治理 advice 的常见配置路径，优先配置：
  - `VCO_INTENT_ADVICE_API_KEY`
  - 可选 `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`
- 向量 diff（可选）：`VCO_VECTOR_DIFF_API_KEY` + 可选 `VCO_VECTOR_DIFF_BASE_URL` + `VCO_VECTOR_DIFF_MODEL`
- 旧 `OPENAI_*` 不会自动迁移成 `VCO_*`

### Claude Code

- 维护 `~/.claude/settings.json`
- 在现有 `env` 对象里增量补 VCO 相关键，不要整体覆盖整个文件
- 如需 AI 治理 advice 的常见配置路径，优先补：
  - `VCO_INTENT_ADVICE_API_KEY`
  - 可选 `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`

### Cursor

- 维护 `~/.cursor/settings.json`
- 视需要在现有 settings 面里增量补本地 provider / MCP / VCO 配置，不要覆盖无关的 Cursor 原生设置

### Windsurf

- 查看 `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf` 下的 `.vibeskills/host-settings.json` 与 `.vibeskills/host-closure.json`
- 把这些文件理解成 repo 维护的 sidecar 状态，不要把它们误当成 Windsurf 官方全局 settings 文件
- 宿主侧登录、provider、模型权限等本地配置仍需在 Windsurf 内完成

### OpenClaw

- 查看 `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw` 下的 runtime-core payload，以及 `.vibeskills/host-settings.json` / `.vibeskills/host-closure.json`
- 如需与脚本安装结果对齐，优先使用 attach / copy / bundle 三路径说明
- 宿主侧登录、provider、模型和编辑器配置仍需在 OpenClaw 内完成

### OpenCode

- 确认 `OPENCODE_HOME` 或 `~/.vibeskills/targets/opencode` 下的 preview payload
- 真实宿主文件是 `~/.config/opencode/opencode.json`
- `<target-root>/opencode.json.example` 只作为示例脚手架；需要手动把你要的配置段复制到真实 `~/.config/opencode/opencode.json`
- 真实 `opencode.json`、provider 凭据、plugin 安装和 MCP 信任仍需宿主侧本地完成
- 如需项目内隔离安装结果，对齐 `./.opencode`

## 这条路径不会自动完成什么

- hook 安装
- provider 凭据写入
- 宿主侧本地配置的自动代管

当前公开支持面里，六个宿主都不应被描述成“已自动安装 hook”。
