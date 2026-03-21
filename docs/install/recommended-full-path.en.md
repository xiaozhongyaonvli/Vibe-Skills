# Install Path: Advanced Host / Lane Reference

> Most users should start with the two main install paths:
> - [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md)
> - [`manual-copy-install.en.md`](./manual-copy-install.en.md)

This document exists to explain the current real support boundary.

## Current Supported Surface

At the moment, only two hosts are supported:

- `codex`
- `claude-code`

Within that scope:

- `codex`: recommended path
- `claude-code`: preview scaffold path

`TargetRoot` is only the install path.
`HostId` / `--host` is what decides host semantics.

## Recommended Commands

### Codex

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
bash ./check.sh --host codex --profile full --deep
```

### Claude Code

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
bash ./check.sh --host claude-code --profile full --deep
```

## Boundaries That Must Stay Explicit

### Codex

- this is the strongest repo-governed path today
- guidance should stay limited to local `~/.codex` settings, official MCP registration, and optional CLI dependencies
- do not treat unproven hook/plugin surfaces as standard install requirements
- if online model access is needed, point users to `~/.codex/settings.json` under `env` or local environment variables
- do not ask users to paste secrets into chat

### Claude Code

- this is preview scaffold support, not full closure
- the installer writes `settings.vibe.preview.json` only as a reference and does not overwrite the real `settings.json`
- users should open `~/.claude/settings.json` and add only the required fields under `env`
- common fields are:
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- add `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` only when needed for the host connection
- do not ask users to paste secrets into chat

## AI Governance Reminder

For `claude-code`, if `url`, `apikey`, and `model` are not configured locally yet, the environment must not be described as online-ready.

Those values must be filled by the user in local host settings or local environment variables.
