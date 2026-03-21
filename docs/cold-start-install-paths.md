# 冷启动安装路径

这份文档先回答两个问题：

- 你要的是哪条 adapter lane
- 你要的是 full governed、preview scaffold，还是 runtime-core-only

## 一句话先说清楚

- `codex`：当前唯一的正式 governed-with-constraints 路径
- `claude-code`：现在有 preview scaffold + preview check，但不是满闭环
- `generic` / `opencode`：只安装 runtime-core，到中性目录，不写宿主特定状态

再强调一次：

- `TargetRoot` 只是路径
- `HostId` / `--host` 才决定 adapter 语义

## 路径一：Codex 正式路径

适合要完整 install/check/bootstrap 的用户。

Windows:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
```

Linux / macOS:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
```

你会得到：

- governed payload
- provider seed 可选写入
- MCP active profile 物化
- deep health check

## 路径二：Claude Code 预览路径

适合想把仓库接到 Claude Code，但接受 preview truth 的用户。

Windows:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
```

Linux / macOS:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
```

你会得到：

- runtime-core payload
- `settings.template.claude.json` 生成的 preview `settings.json`
- hooks scaffold
- preview health check

你不会得到：

- 自动插件 provision
- 自动 MCP host 注册
- 自动 provider secret 写入

## 路径三：Neutral Runtime-Core

适合只想拿 canonical skills / commands / mirrored `skills/vibe` 的用户。

```powershell
pwsh -File .\install.ps1 -HostId generic -Profile full
pwsh -File .\check.ps1 -HostId generic -Profile full
```

```bash
bash ./install.sh --host generic --profile full
bash ./check.sh --host generic --profile full
```

关键边界：

- 默认目标根目录是中性的 `.vibe-skills/generic`
- 不应该把 neutral lane 写进 `.codex` 或 `.claude`
- provider URL、API key、model 仍由用户自己提供给目标宿主
