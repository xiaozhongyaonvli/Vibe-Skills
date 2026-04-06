# 多宿主安装命令参考

> 普通用户优先看：
>
> - [`one-click-install-release-copy.md`](./one-click-install-release-copy.md)
> - [`manual-copy-install.md`](./manual-copy-install.md)
> - [`openclaw-path.md`](./openclaw-path.md)
> - [`opencode-path.md`](./opencode-path.md)

这份文档汇总当前六个公开宿主对应的安装命令、默认目标根目录与 host-mode 说明。

Linux / macOS 公共前置条件：

- shell 入口按 **macOS 自带 Bash 3.2** 兼容维护
- `python3` / `python` 需要满足 **Python 3.10+**
- 从 `zsh` 启动不是问题本身；真正关键是解析到的 `bash` / `python3` 版本

## 支持宿主与默认路径

| 宿主 | 默认命令面 | 默认目标根目录 | 当前口径 |
| --- | --- | --- | --- |
| `codex` | one-shot setup + check | `CODEX_HOME` 或 `~/.vibeskills/targets/codex` | strongest governed lane |
| `claude-code` | one-shot setup + check | `CLAUDE_HOME` 或 `~/.vibeskills/targets/claude-code` | supported install/use path with bounded managed closure |
| `cursor` | one-shot setup + check | `CURSOR_HOME` 或 `~/.vibeskills/targets/cursor` | preview-guidance path |
| `windsurf` | one-shot setup + check | `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf` | runtime-core path |
| `openclaw` | one-shot setup + check | `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw` | preview runtime-core adapter path |
| `opencode` | direct install + check（更薄）或 one-shot wrapper | `OPENCODE_HOME` 或 `~/.vibeskills/targets/opencode` | preview-guidance adapter path |

`TargetRoot` 只是路径。
`HostId` / `--host` 才决定宿主语义。

## 推荐命令

默认全量安装：

### Codex

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex -Profile full
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex --profile full
bash ./check.sh --host codex --profile full --deep
```

### Claude Code

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code -Profile full
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code --profile full
bash ./check.sh --host claude-code --profile full --deep
```

### Cursor

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId cursor -Profile full
pwsh -File .\check.ps1 -HostId cursor -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host cursor --profile full
bash ./check.sh --host cursor --profile full --deep
```

### Windsurf

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId windsurf -Profile full
pwsh -File .\check.ps1 -HostId windsurf -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host windsurf --profile full
bash ./check.sh --host windsurf --profile full --deep
```

### OpenClaw

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId openclaw -Profile full
pwsh -File .\check.ps1 -HostId openclaw -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host openclaw --profile full
bash ./check.sh --host openclaw --profile full --deep
```

### OpenCode

更薄的默认路径：

```powershell
pwsh -NoProfile -File .\install.ps1 -HostId opencode -Profile full
pwsh -NoProfile -File .\check.ps1 -HostId opencode -Profile full
```

```bash
bash ./install.sh --host opencode --profile full
bash ./check.sh --host opencode --profile full
```

如果你更希望沿用统一 bootstrap wrapper，也可以：

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId opencode -Profile full
pwsh -File .\check.ps1 -HostId opencode -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host opencode --profile full
bash ./check.sh --host opencode --profile full --deep
```

如果你要装“仅核心框架 + 可自定义添加治理”，把上面的 `full` 改成 `minimal`。

## 更新方式

如果本地还保留仓库，先更新仓库再重跑同一组命令：

```bash
git pull origin main
```

如果你跟随 tag 发布版本而不是 `main`，则：

```bash
git fetch --tags --force
git checkout vX.Y.Z
```

## 手动设置路径与修改方式

当文档说“你还需要本地配置”时，应该明确到真实文件或路径，而不是只说一句“请手动设置”。

| 宿主 | 真实要改或要看的路径 | 应该怎么设置 |
| --- | --- | --- |
| `codex` | `<target-root>/settings.json`，默认 `~/.codex/settings.json` | 编辑顶层 `env` 对象，补 `VCO_INTENT_ADVICE_*`；只有需要向量 diff 时再补 `VCO_VECTOR_DIFF_*` |
| `claude-code` | `~/.claude/settings.json` | 在现有 `env` 对象里增量补键，保留原有 Claude 设置 |
| `cursor` | `~/.cursor/settings.json` | 在真实 settings 文件里增量补键；repo 可能只在其中物化一个受限的最小 Vibe 设置面，但不会接管无关的 Cursor 原生设置 |
| `windsurf` | 查看 `<target-root>/.vibeskills/host-settings.json`；默认目标根目录是 `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf` | 这里是 repo 自己维护的 sidecar 状态；真正的登录、provider、模型权限仍需在 Windsurf 宿主侧完成 |
| `openclaw` | 查看 `<target-root>/.vibeskills/host-settings.json`；默认目标根目录是 `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw` | 这里是 repo 自己维护的 sidecar 状态；真正的登录、provider、模型和编辑器设置仍需在 OpenClaw 宿主侧完成 |
| `opencode` | 编辑真实宿主文件 `~/.config/opencode/opencode.json`；`<target-root>/opencode.json.example` 只作为示例脚手架 | 从 example 里复制你需要的 permission / command / provider 结构到真实宿主文件；repo 不会覆盖真实 `opencode.json` |

对于使用 `env` 对象的宿主，建议按下面的结构补：

```json
{
  "env": {
    "VCO_INTENT_ADVICE_API_KEY": "<你的主治理 API Key>",
    "VCO_INTENT_ADVICE_BASE_URL": "https://your-openai-compatible-endpoint/v1",
    "VCO_INTENT_ADVICE_MODEL": "your-intent-advice-model-id",
    "VCO_VECTOR_DIFF_API_KEY": "<可选的 vector diff API Key>",
    "VCO_VECTOR_DIFF_BASE_URL": "https://your-openai-compatible-endpoint/v1",
    "VCO_VECTOR_DIFF_MODEL": "your-vector-diff-model-id"
  }
}
```

说明：

- `VCO_VECTOR_DIFF_*` 是可选的；缺失时 diff 会退化成普通文本
- 旧 `OPENAI_*` 不会自动迁移成 `VCO_*`，需要你在本地文件或本地环境变量里手动迁移
- 不要把密钥贴到聊天里，始终放在本地 settings 文件或本地环境变量里

## 安装后仍需你本地处理的内容

### Codex

- hook 当前冻结；这不是安装失败
- 编辑 `<target-root>/settings.json`，默认就是 `~/.codex/settings.json`
- 把这些值放在顶层 `env` 对象下，不要另起一个自定义块
- AI 治理 advice 的常见配置路径，优先使用：
  - `VCO_INTENT_ADVICE_API_KEY`
  - 可选 `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`
- 向量 diff（可选）：添加 `VCO_VECTOR_DIFF_API_KEY` / `VCO_VECTOR_DIFF_BASE_URL` / `VCO_VECTOR_DIFF_MODEL`
- 旧 `OPENAI_*` 不会自动回填到这些键

### Claude Code

- 会在保留真实 `~/.claude/settings.json` 的前提下，增量合并受约束的 `vibeskills` 设置面
- 继续编辑 `~/.claude/settings.json` 里的现有 `env` 对象，不要整体覆盖这个文件
- 更广的 Claude 插件、MCP 注册、凭据和宿主行为仍由宿主侧管理
- AI 治理 advice 使用 `VCO_INTENT_ADVICE_*`，可选再补 `VCO_VECTOR_DIFF_*`

### Cursor

- 当前是 preview-guidance 路径
- 如果需要继续本地补配置，就编辑真实 `~/.cursor/settings.json`
- repo 可能只在其中物化一个受限的最小 Vibe 设置面，但不会接管无关的 Cursor 原生设置
- 如需补本地 provider 或治理键，请在这个文件里增量合并，而不是覆盖无关的 Cursor 原生设置
- Cursor 的宿主原生设置与扩展面仍按 Cursor 自身方式管理

### Windsurf

- 默认目标根目录是 `WINDSURF_HOME`，否则是 `~/.vibeskills/targets/windsurf`
- 查看 `<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json` 来确认 repo 侧状态
- repo 当前不声明一个权威的 Windsurf 全局 `settings.json` 路径
- Windsurf 宿主自身的本地设置仍按 Windsurf 自身方式管理

### OpenClaw

- 默认目标根目录是 `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw`
- 查看 `<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json` 来确认 repo 侧状态
- 宿主专页会展开 attach / copy / bundle 等细节
- OpenClaw 宿主自身的本地配置仍按 OpenClaw 自身方式管理；不要凭空假设一个 repo 接管的 `settings.json` 路径

### OpenCode

- 默认目标根目录是 `OPENCODE_HOME`，否则是 `~/.vibeskills/targets/opencode`
- 真实宿主配置目录 `~/.config/opencode` 仍由 OpenCode 自身管理
- direct install/check 与 one-shot wrapper 都保持 host-managed 边界
- 真实 `opencode.json`、provider 凭据、plugin 安装和 MCP 信任仍按宿主自身方式管理
- 请手动编辑真实文件 `~/.config/opencode/opencode.json`，并把 `<target-root>/opencode.json.example` 仅当作参考脚手架
- 如需项目内隔离安装，使用 `--target-root ./.opencode`
