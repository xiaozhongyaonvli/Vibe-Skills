# Multi-Host Install Command Reference

> Most users should start with:
>
> - [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md)
> - [`manual-copy-install.en.md`](./manual-copy-install.en.md)
> - [`openclaw-path.en.md`](./openclaw-path.en.md)
> - [`opencode-path.en.md`](./opencode-path.en.md)

This document summarizes the install commands, default target roots, and current host-mode wording for the six public hosts.

Public Linux / macOS prerequisites:

- the shell entrypoints are maintained against the macOS system Bash 3.2 baseline
- `python3` / `python` must satisfy **Python 3.10+**
- launching from `zsh` is not the actual problem; the real compatibility boundary is the resolved `bash` / `python3` version

## Supported Hosts and Default Paths

| Host | Default command surface | Default root | Current wording |
| --- | --- | --- | --- |
| `codex` | one-shot setup + check | `CODEX_HOME` or `~/.vibeskills/targets/codex` | strongest governed lane |
| `claude-code` | one-shot setup + check | `CLAUDE_HOME` or `~/.vibeskills/targets/claude-code` | supported install/use path with bounded managed closure |
| `cursor` | one-shot setup + check | `CURSOR_HOME` or `~/.vibeskills/targets/cursor` | preview-guidance path |
| `windsurf` | one-shot setup + check | `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf` | runtime-core path |
| `openclaw` | one-shot setup + check | `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw` | preview runtime-core adapter path |
| `opencode` | direct install + check (thinner) or one-shot wrapper | `OPENCODE_HOME` or `~/.vibeskills/targets/opencode` | preview-guidance adapter path |

`TargetRoot` is only a path.
`HostId` / `--host` decides host semantics.

## Recommended Commands

Default full install:

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

The thinner default path is:

```powershell
pwsh -NoProfile -File .\install.ps1 -HostId opencode -Profile full
pwsh -NoProfile -File .\check.ps1 -HostId opencode -Profile full
```

```bash
bash ./install.sh --host opencode --profile full
bash ./check.sh --host opencode --profile full
```

If you prefer to keep the same bootstrap wrapper as other hosts, this is also valid:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId opencode -Profile full
pwsh -File .\check.ps1 -HostId opencode -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host opencode --profile full
bash ./check.sh --host opencode --profile full --deep
```

If you want the “Framework Only + Customizable Governance” variant, replace `full` with `minimal`.

## Upgrade Flow

If you still have a local checkout, update the repo first and then rerun the same commands:

```bash
git pull origin main
```

If you follow tagged releases instead of `main`, use:

```bash
git fetch --tags --force
git checkout vX.Y.Z
```

## Manual Settings Paths and Edit Pattern

When a follow-up step says "configure locally", it should name the real file or path below instead of telling operators only to "set it manually".

| Host | Real path to edit or inspect | How to set it |
| --- | --- | --- |
| `codex` | `<target-root>/settings.json`, default `~/.codex/settings.json` | edit the top-level `env` object and add `VCO_INTENT_ADVICE_*`; add `VCO_VECTOR_DIFF_*` only when you want vector diff embeddings |
| `claude-code` | `~/.claude/settings.json` | merge the needed keys into the existing `env` object; keep unrelated Claude settings intact |
| `cursor` | `~/.cursor/settings.json` | merge the needed keys into the real settings file; the repo may materialize a bounded minimal Vibe surface there, but it does not take over unrelated Cursor settings |
| `windsurf` | inspect `<target-root>/.vibeskills/host-settings.json`; default target root is `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf` | treat this as repo-owned sidecar state only; host-native login, provider, and model-permission settings still need to be configured on the Windsurf side |
| `openclaw` | inspect `<target-root>/.vibeskills/host-settings.json`; default target root is `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw` | treat this as repo-owned sidecar state only; host-native login, provider, model, and editor settings still need to be configured on the OpenClaw side |
| `opencode` | edit the real host file `~/.config/opencode/opencode.json`; use `<target-root>/opencode.json.example` only as a scaffold | copy only the needed permission / command / provider structure from the example into the real host file; the repository does not overwrite the real `opencode.json` |

For hosts that use an `env` object, the intended edit pattern is:

```json
{
  "env": {
    "VCO_INTENT_ADVICE_API_KEY": "<your-intent-advice-api-key>",
    "VCO_INTENT_ADVICE_BASE_URL": "https://your-openai-compatible-endpoint/v1",
    "VCO_INTENT_ADVICE_MODEL": "your-intent-advice-model-id",
    "VCO_VECTOR_DIFF_API_KEY": "<optional-vector-diff-api-key>",
    "VCO_VECTOR_DIFF_BASE_URL": "https://your-openai-compatible-endpoint/v1",
    "VCO_VECTOR_DIFF_MODEL": "your-vector-diff-model-id"
  }
}
```

Notes:

- `VCO_VECTOR_DIFF_*` is optional; if it is absent, diff falls back to plain text
- old `OPENAI_*` values are not auto-migrated into `VCO_*`; move them explicitly in the local file or local environment
- do not paste secrets into chat; keep them in the local settings file or local environment variables

## What You Still Handle Locally After Install

### Codex

- hooks remain frozen; that is not an install failure
- edit `<target-root>/settings.json`, default `~/.codex/settings.json`
- put the values under the top-level `env` object instead of creating a second custom block
- for the built-in governance-advice path, prefer:
  - `VCO_INTENT_ADVICE_API_KEY`
  - optional `VCO_INTENT_ADVICE_BASE_URL`
  - `VCO_INTENT_ADVICE_MODEL`
- add `VCO_VECTOR_DIFF_*` only when you also want vector diff embeddings
- old `OPENAI_*` values do not backfill these keys automatically

### Claude Code

- it preserves the real `~/.claude/settings.json` while merging a bounded managed `vibeskills` settings surface
- edit the existing `env` object in `~/.claude/settings.json`; do not replace the whole file
- broader Claude plugins, MCP registration, credentials, and host behavior remain host-managed
- AI governance advice uses `VCO_INTENT_ADVICE_*`, with optional `VCO_VECTOR_DIFF_*`

### Cursor

- this host is currently a preview-guidance path
- when local follow-up is needed, edit the real `~/.cursor/settings.json`
- the repo may materialize a bounded minimal Vibe-managed surface there, but it does not take over unrelated Cursor settings
- when you add local provider or governance keys, merge them into the existing settings file instead of replacing unrelated Cursor settings
- Cursor-native settings and extension surfaces remain managed on the Cursor side

### Windsurf

- the default target root is `WINDSURF_HOME`, otherwise `~/.vibeskills/targets/windsurf`
- inspect `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json` for repo-owned state
- the repo does not claim an authoritative global `settings.json` path for Windsurf
- Windsurf-native local settings remain managed on the Windsurf side

### OpenClaw

- the default target root is `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- inspect `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json` for repo-owned state
- the dedicated host guide expands attach / copy / bundle details
- OpenClaw-local configuration remains managed on the OpenClaw side; do not invent an undocumented repo-owned `settings.json` path

### OpenCode

- the default target root is `OPENCODE_HOME`, otherwise `~/.vibeskills/targets/opencode`
- the real host config directory `~/.config/opencode` remains host-managed
- both direct install/check and the one-shot wrapper keep host-managed boundaries intact
- the real `opencode.json`, provider credentials, plugin installation, and MCP trust remain host-managed
- edit the real file `~/.config/opencode/opencode.json` yourself, and use `<target-root>/opencode.json.example` only as the reference scaffold
- use `--target-root ./.opencode` when you want project-local isolation
