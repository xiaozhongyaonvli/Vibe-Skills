# 配置指南

这份指南只澄清一件事：安装完成后，怎样把 AI 治理 advice 的在线配置补齐。

## 先分清两件事

- `本地安装完成`：脚本或复制动作已经把 VibeSkills 放进目标宿主根目录。
- `AI 治理 online-ready`：路由里的 advice 在线调用已经拿到本地凭据、模型名和可用的 provider 地址。

前者成立，不代表后者也成立。

## 快速检查实际读取哪里

当前快速检查会优先读取：

1. `<target-root>/settings.json` 里的 `env`
2. 当前 shell / process environment

也就是说：

- 如果宿主本地维护 `settings.json`，优先把变量放到那个 `env`
- 如果宿主不走这个文件面，或者你只是先做连通性验证，也可以先放到本地环境变量

不要把密钥贴到聊天里。

## 手动设置时到底改哪个文件

当安装说明要求你“继续本地设置”时，应该直接落到下面这些真实路径，而不是停留在“自己配一下”这种模糊描述：

| 宿主 | 真实路径 / 文件 | 应该怎么设置 |
| --- | --- | --- |
| `codex` | `<target-root>/settings.json`，默认就是 `~/.codex/settings.json` | 打开文件，找到或创建顶层 `env` 对象，把 `VCO_INTENT_ADVICE_*` 写进去；只有需要向量 diff 时再补 `VCO_VECTOR_DIFF_*` |
| `claude-code` | `~/.claude/settings.json` | 在现有 `env` 对象里增量补 `VCO_*` 键，不要整体覆盖整个文件 |
| `cursor` | `~/.cursor/settings.json` | 在真实 settings 文件里增量补 `VCO_*` 键；repo 可能会在这里物化一个受限的最小 Vibe 设置面，但不会接管无关的 Cursor 原生设置 |
| `windsurf` | 查看 `<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json`；默认目标根目录是 `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf` | 这些文件只用来确认 repo 写入了哪些 sidecar 状态；真正的登录、provider、模型权限仍在 Windsurf 宿主侧配置。若只想先验证 AI advice 连通性，可先在本地环境变量里设置 `VCO_*` |
| `openclaw` | 查看 `<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json`；默认目标根目录是 `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw` | 这些文件只用来确认 repo 写入了哪些 sidecar 状态；真正的登录、provider、模型和编辑器行为仍在 OpenClaw 宿主侧配置。若只想先验证 AI advice 连通性，可先在本地环境变量里设置 `VCO_*` |
| `opencode` | 真实宿主文件是 `~/.config/opencode/opencode.json`；参考脚手架是 `<target-root>/opencode.json.example` | 先打开真实宿主文件，再对照 example，把你真正需要的 permission / command / provider 结构复制进去；provider 凭据与 MCP 信任仍在 OpenCode 宿主侧维护 |

对于会用 `env` 对象的宿主，建议按下面这个结构补：

```json
{
  "env": {
    "VCO_INTENT_ADVICE_API_KEY": "<local-api-key>",
    "VCO_INTENT_ADVICE_BASE_URL": "https://api.openai.com/v1",
    "VCO_INTENT_ADVICE_MODEL": "gpt-5.4-high",
    "VCO_VECTOR_DIFF_API_KEY": "<optional-vector-diff-key>",
    "VCO_VECTOR_DIFF_BASE_URL": "https://api.openai.com/v1",
    "VCO_VECTOR_DIFF_MODEL": "text-embedding-3-small"
  }
}
```

说明：

- `VCO_VECTOR_DIFF_*` 是可选的；缺失时 diff 会退化成普通文本
- 旧 `OPENAI_*` 不会自动迁移到 `VCO_*`
- 不要把 secrets 发到聊天里，只放到本地 settings 文件或本地环境变量

## 内置 intent advice 与 vector diff 配置

内置 AI 治理在 `/vibe` 执行时需要两类配置：
- 主路径（intent advice）：用于 `advice` 请求和各类问答/confirm screen，必须配置凭据、模型、可选 base URL。
- 增强路径（vector diff embeddings）：用于 diff 选取，属于可选降级能力，缺失时 diff 仍然回退为普通文本片段。

### intent advice keys（必须）

```json
{
  "env": {
    "VCO_INTENT_ADVICE_API_KEY": "<local-api-key>",
    "VCO_INTENT_ADVICE_BASE_URL": "https://api.openai.com/v1",
    "VCO_INTENT_ADVICE_MODEL": "gpt-5.4-high"
  }
}
```

- `VCO_INTENT_ADVICE_API_KEY`：主授权凭据，缺失时 advice 无法启动，快速检查会标记 `missing_credentials`。
- `VCO_INTENT_ADVICE_BASE_URL`：可选用户网关，默认使用 policy 或 provider 默认地址。
- `VCO_INTENT_ADVICE_MODEL`：用于 `provider.model` 替代原 `VCO_RUCNLPIR_MODEL` 的语义。

### vector diff embeddings keys（可选）

```json
{
  "env": {
    "VCO_VECTOR_DIFF_API_KEY": "<local-embedding-key>",
    "VCO_VECTOR_DIFF_BASE_URL": "https://api.openai.com/v1",
    "VCO_VECTOR_DIFF_MODEL": "text-embedding-3-small"
  }
}
```

- vector diff 仅在 `config/llm-acceleration-policy.json` 的 `context.vector_diff.enabled` 为 `true` 且上述凭据齐全时才会调用。
- 缺失 `VCO_VECTOR_DIFF_API_KEY`/`VCO_VECTOR_DIFF_MODEL` 时，diff 模块会发出 `vector_diff_missing_credentials` 警告，但不会阻断 advice。
- 该路径默认不会回退到旧的 `OPENAI_API_KEY` / `OPENAI_BASE_URL`，用户需要显式维护新的键名。

## 当前公共口径

当前推荐的配置方式不再依赖旧 `OPENAI_*` 键名，统一以 `VCO_INTENT_ADVICE_*` 打头；vector diff 也使用独立的 `VCO_VECTOR_DIFF_*` 键。旧的 `OPENAI_API_KEY` 不再自动回填，必须自己迁移到新键名。

## 内置治理层的 provider 边界

内置 AI 治理依然以 OpenAI-compatible 协议为主：

- advice 链路使用 `responses`/`chat_completions`，并从 `VCO_INTENT_ADVICE_*` 读取凭据。
- diff 链路仍按 OpenAI-compatible embeddings 接口工作，但只在所有新键就绪时触发。
- 其他 provider 形态可以通过策略文件（`config/llm-acceleration-policy.json`）指定 `provider.base_url`/`provider.model`，但本地凭据仍建议放在两个 VCO_* 键里。

## 高级路径：策略文件里直接指定 provider

如果你已经在仓库策略里维护 provider，也可以继续保留：

- `config/llm-acceleration-policy.json` 的 `provider.base_url`
- `config/llm-acceleration-policy.json` 的 `provider.model`

这种情况下：

- base URL / model 可以来自策略文件
- 本地凭据仍建议放在 `VCO_INTENT_ADVICE_API_KEY`

## 不同宿主通常放哪里

### Codex

- 目标根目录：`CODEX_HOME` 或 `~/.vibeskills/targets/codex`
- 常见位置：`~/.codex/settings.json` 的 `env`

### Claude Code

- 目标根目录：`CLAUDE_HOME` 或 `~/.vibeskills/targets/claude-code`
- 常见位置：`~/.claude/settings.json` 的 `env`

### Cursor

- 目标根目录：`CURSOR_HOME` 或 `~/.vibeskills/targets/cursor`
- 真实文件：`~/.cursor/settings.json`
- 常见做法：在现有 settings 面里增量补 `env` / `VCO_*` 键；repo 可能会在这里物化一个受限的最小 Vibe 设置面，但不会接管无关的 Cursor 原生设置

### Windsurf

- 目标根目录：`WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf`
- repo 侧可检查文件：`<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json`
- 如果宿主侧没有直接使用 `<target-root>/settings.json`，就在本地环境变量里配置 `VCO_*` 再做检查

### OpenClaw

- 目标根目录：`OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw`
- repo 侧可检查文件：`<target-root>/.vibeskills/host-settings.json` 与 `<target-root>/.vibeskills/host-closure.json`
- 如果宿主侧没有直接使用 `<target-root>/settings.json`，就在本地环境变量里配置 `VCO_*` 再做检查

### OpenCode

- 目标根目录：`OPENCODE_HOME` 或 `~/.vibeskills/targets/opencode`
- 真实宿主配置目录仍是 `~/.config/opencode`
- 要手动编辑的真实文件是 `~/.config/opencode/opencode.json`
- 可参考 `<target-root>/opencode.json.example`，但不要把它误当成真实生效文件
- 如果宿主侧没有直接使用 `<target-root>/settings.json`，就在本地环境变量里配置 `VCO_*` 再做检查

## 快速检查命令

在仓库根目录运行：

### Windows

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-router-ai-connectivity-gate.ps1 -TargetRoot "<目标宿主根目录>" -WriteArtifacts
```

如果本机已经安装了 PowerShell 7，也可以改成 `pwsh`。

### Linux / macOS

```bash
python3 ./scripts/verify/runtime_neutral/router_ai_connectivity_probe.py --target-root "<目标宿主根目录>" --write-artifacts
```

常见默认目标根目录：

- `codex` -> `CODEX_HOME` 或 `~/.vibeskills/targets/codex`
- `claude-code` -> `CLAUDE_HOME` 或 `~/.vibeskills/targets/claude-code`
- `cursor` -> `CURSOR_HOME` 或 `~/.vibeskills/targets/cursor`
- `windsurf` -> `WINDSURF_HOME` 或 `~/.vibeskills/targets/windsurf`
- `openclaw` -> `OPENCLAW_HOME` 或 `~/.vibeskills/targets/openclaw`
- `opencode` -> `OPENCODE_HOME` 或 `~/.vibeskills/targets/opencode`

## 结果怎么看

- `ok`：AI 治理 advice 已连通
- `missing_credentials`：缺本地密钥，优先补 `VCO_INTENT_ADVICE_API_KEY`
- `missing_model`：缺模型名，优先补 `VCO_INTENT_ADVICE_MODEL`
- `missing_base_url`：需要补 `VCO_INTENT_ADVICE_BASE_URL` 或在策略文件里补 `provider.base_url`
- `provider_rejected_request`：密钥、模型名或 endpoint 兼容性有问题
- `provider_unreachable`：网络、DNS、base URL 可达性或超时有问题
- `prefix_required`：当前策略要求在 `/vibe` 显式作用域下再检查 advice

## 安装后如果要卸载

当你需要回滚当前安装时，使用仓库根目录下的 `uninstall.ps1` 或 `uninstall.sh`：

- Windows：
  - `pwsh -NoProfile -File .\uninstall.ps1 --host <host> --target-root "<目标宿主根目录>"`
- Linux / macOS：
  - `bash ./uninstall.sh --host <host> --target-root "<目标宿主根目录>"`

这两个卸载入口与 `install.*` 参数对称，默认直接执行，但遵守 [`../uninstall-governance.md`](../uninstall-governance.md) 里的 ledger-first、owned-only 契约：只删除 install ledger、host closure 或保守 legacy 规则能够证明属于 Vibe 的内容；共享配置文件里只移除 `vibeskills` 受管节点。

## 最短实践结论

如果你只想最快补齐内置 AI 治理能力：

1. 在本地 `settings.json` 的 `env`，或本地环境变量里配置 `VCO_INTENT_ADVICE_API_KEY`
2. 如有自定义网关，再补 `VCO_INTENT_ADVICE_BASE_URL`
3. 配置 `VCO_INTENT_ADVICE_MODEL`
4. 跑一次快速检查

向量 diff 可选：如果需要更好的 diff 体验，再添加 `VCO_VECTOR_DIFF_API_KEY`/`VCO_VECTOR_DIFF_MODEL`（base URL 同样可选）。
