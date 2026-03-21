# 手动复制安装（离线 / 无管理员权限）

这是第二条主路径，但当前也只面向两个支持宿主：

- `codex`
- `claude-code`

如果你的目标不是这两个宿主，当前版本不建议安装，也不要把手动复制描述成“已支持”。

## 你会得到什么

手动复制安装得到的是仓库侧 runtime 载荷，不是完整宿主闭环。

也就是说，你会得到：

- `skills/`
- `commands/`
- `config/upstream-lock.json`
- `config/skills-lock.json`（如果存在）
- `skills/vibe/` 这套 canonical runtime mirror

但你不会自动得到：

- 宿主插件 provision
- MCP 注册
- provider 凭据写入
- Claude Code 真实 `settings.json` 的自动合并

## 手动复制步骤

假设目标目录是：`<TARGET_ROOT>`

1. 创建目标目录结构

```bash
mkdir -p <TARGET_ROOT>/skills <TARGET_ROOT>/commands <TARGET_ROOT>/config
```

2. 复制 runtime skills

```bash
cp -R ./bundled/skills/. <TARGET_ROOT>/skills/
```

3. 复制命令目录

```bash
cp -R ./commands/. <TARGET_ROOT>/commands/
```

4. 复制锁文件

```bash
cp ./config/upstream-lock.json <TARGET_ROOT>/config/upstream-lock.json
cp ./config/skills-lock.json <TARGET_ROOT>/config/skills-lock.json
```

如果 `skills-lock.json` 不存在，就跳过它。

## 支持宿主的后续动作

### Codex

- 打开 `~/.codex/settings.json`
- 只在 `env` 下补你需要的字段
- 常见是 `OPENAI_API_KEY`、`OPENAI_BASE_URL`
- 不要把密钥贴到聊天里

### Claude Code

- 打开 `~/.claude/settings.json`
- 只在 `env` 下补你需要的字段
- 常见是：
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- 如宿主连接需要，再补 `ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`
- 可以参考 `~/.claude/settings.vibe.preview.json`，但不能整文件覆盖
- 不要把密钥贴到聊天里

## 最重要的边界

- 这条路不会自动帮你写好 online provider 配置
- 如果 `url` / `apikey` / `model` 没有在本地配置好，就不能把环境描述成“已完成 online readiness”
- 当前版本不把其他代理视为正式支持面

## 什么时候不要走这条路

下面这些情况，优先走提示词安装：

- 你希望 AI 帮你判断该走哪个宿主
- 你希望脚本自动做 install + check
- 你不想自己处理本地配置说明

对应主入口：

- [`one-click-install-release-copy.md`](./one-click-install-release-copy.md)
