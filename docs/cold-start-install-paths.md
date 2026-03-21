# 冷启动安装路径

这份文档只回答冷启动阶段最重要的问题：当前支持哪个宿主、该走哪条路径。

## 一句话结论

暂时只支持两个宿主：

- `codex`
- `claude-code`

其中：

- `codex`：正式推荐路径
- `claude-code`：预览路径

如果你要装到其他代理，当前版本应视为不支持，而不是改走隐藏 lane。

## 路径一：Codex

Windows:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
```

Linux / macOS:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
bash ./check.sh --host codex --profile full --deep
```

你会得到：

- governed payload
- 可选的 provider seed 写入
- MCP active profile 物化
- deep health check

## 路径二：Claude Code

Windows:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
```

Linux / macOS:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
bash ./check.sh --host claude-code --profile full --deep
```

你会得到：

- runtime payload
- `settings.vibe.preview.json` 示例 scaffold
- preview health check

你不会得到：

- 自动覆盖真实 `settings.json`
- 自动插件 provision
- 自动 MCP 宿主注册
- 自动 provider secret 写入

## Claude Code 的正确后续动作

- 打开 `~/.claude/settings.json`
- 只在 `env` 下补你需要的字段
- 常见是 `VCO_AI_PROVIDER_URL`、`VCO_AI_PROVIDER_API_KEY`、`VCO_AI_PROVIDER_MODEL`
- 如宿主连接需要，再补 `ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`
- 参考 `~/.claude/settings.vibe.preview.json`，但不要整文件覆盖
- 不要把密钥贴到聊天里

## 冷启动阶段最重要的边界

- `HostId` / `--host` 决定宿主语义，不是路径名决定
- 当前没有其他宿主的公开安装入口
- 如果本地还没配好 `url` / `apikey` / `model`，不能描述成“已完成 online readiness”
