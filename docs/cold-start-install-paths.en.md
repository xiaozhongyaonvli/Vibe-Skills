# Cold-Start Install Paths

This document answers the only cold-start questions that matter right now: which hosts are supported, and which path you should use.

## One-Line Conclusion

At the moment, only two hosts are supported:

- `codex`
- `claude-code`

Within that scope:

- `codex`: recommended path
- `claude-code`: preview path

If you want another agent, the current version should be treated as unsupported rather than silently routed into a hidden lane.

## Path 1: Codex

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

What you get:

- governed payload
- optional provider seeding
- MCP active profile materialization
- deep health check

## Path 2: Claude Code

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

What you get:

- runtime payload
- `settings.vibe.preview.json` example scaffold
- preview health check

What you do not get:

- automatic overwrite of the real `settings.json`
- automatic plugin provisioning
- automatic host MCP registration
- automatic provider secret wiring

## Correct Follow-Up For Claude Code

- open `~/.claude/settings.json`
- add only the fields you need under `env`
- common fields are `VCO_AI_PROVIDER_URL`, `VCO_AI_PROVIDER_API_KEY`, and `VCO_AI_PROVIDER_MODEL`
- add `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` only when needed for the host connection
- use `~/.claude/settings.vibe.preview.json` as a reference, not as a full-file replacement
- do not paste secrets into chat

## Most Important Cold-Start Boundary

- `HostId` / `--host` decides host semantics, not the folder name alone
- there is no public install entry for any other host in the current version
- if `url` / `apikey` / `model` are not configured locally yet, the environment must not be described as online-ready
