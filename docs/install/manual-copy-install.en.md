# Manual Copy Install (Offline / No-Admin)

If you do not want to run the install scripts, this path solves only one thing: copying the repo files into the target host root.

The current public host surface includes:

- `codex`
- `claude-code`
- `cursor`
- `windsurf`
- `openclaw`
- `opencode`

## Core Files To Copy

Copy these into the target root:

- `skills/`
- `commands/`
- `config/upstream-lock.json`
- `skills/vibe/`

## Default Host Roots

- `codex` -> `CODEX_HOME` or `~/.vibeskills/targets/codex`
- `claude-code` -> `CLAUDE_HOME` or `~/.vibeskills/targets/claude-code`
- `cursor` -> `CURSOR_HOME` or `~/.vibeskills/targets/cursor`
- `windsurf` -> `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf`
- `openclaw` -> `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- `opencode` -> `OPENCODE_HOME` or `~/.vibeskills/targets/opencode`

If the target is `windsurf`, also note:

- if you need exact parity with the current scripted result, prefer rerunning `install.* --host windsurf`
- the current public contract uses `.vibeskills/host-settings.json` and `.vibeskills/host-closure.json` as the host sidecars instead of `mcp_config.json` / `global_workflows/`

If the target is `opencode`, switch to the OpenCode preview payload:

- `skills/`
- `.vibeskills/host-settings.json`
- `.vibeskills/host-closure.json`
- `.vibeskills/install-ledger.json`
- `.vibeskills/bin/*-specialist-wrapper.*`
- `opencode.json.example`

Then use [`opencode-path.en.md`](./opencode-path.en.md) for the preview-adapter follow-up steps.

## What You Still Need To Do Yourself

### Codex

- maintain `~/.codex/settings.json`
- edit the top-level `env` object directly; do not create a second custom secrets block
- for the built-in governance-advice path, prefer:
  - `VCO_INTENT_ADVICE_API_KEY`
  - optional `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`
  - `VCO_VECTOR_DIFF_API_KEY` / `VCO_VECTOR_DIFF_BASE_URL` / `VCO_VECTOR_DIFF_MODEL` when embedding-powered diff context is desired
- old `OPENAI_*` values are not auto-migrated into `VCO_*`

### Claude Code

- maintain `~/.claude/settings.json`
- merge the VCO keys into the existing `env` object instead of replacing the whole file
- for the built-in governance-advice path, prefer:
  - `VCO_INTENT_ADVICE_API_KEY`
  - optional `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`
  - `VCO_VECTOR_DIFF_*` keys only when vector diff embeddings are configured; otherwise the advice path still works

### Cursor

- maintain `~/.cursor/settings.json`
- merge local provider / MCP / VCO keys into the existing settings surface without overwriting unrelated Cursor settings

### Windsurf

- inspect `.vibeskills/host-settings.json` and `.vibeskills/host-closure.json` under `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf`
- treat those files as repo-owned sidecar state, not as proof that the repo owns a Windsurf global settings file
- finish host-local login, provider, and model-permission configuration inside Windsurf itself

### OpenClaw

- inspect the runtime-core payload plus `.vibeskills/host-settings.json` / `.vibeskills/host-closure.json` under `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- use the attach / copy / bundle guidance when you want parity with the scripted path
- finish host-local login, provider, model, and editor configuration inside OpenClaw itself

### OpenCode

- confirm the preview payload under `OPENCODE_HOME` or `~/.vibeskills/targets/opencode`
- the real host-managed file is `~/.config/opencode/opencode.json`
- use `<target-root>/opencode.json.example` only as a scaffold, then copy the needed sections into the real `~/.config/opencode/opencode.json`
- keep the real `opencode.json`, provider credentials, plugin installation, and MCP trust host-managed
- use `./.opencode` when you want a project-local isolated target

## What This Path Does Not Complete Automatically

- hook installation
- provider credential wiring
- automatic takeover of host-local configuration

Across the current public surface, none of the six hosts should be described as “hooks installed automatically.”
