# Manual Copy Install (Offline / No-Admin)

This is the second main path, but it still only supports the same two hosts:

- `codex`
- `claude-code`

If your target is not one of those two hosts, the current version should be treated as unsupported. Do not describe manual copy as successful host support.

## What You Get

Manual copy gives you the repo-owned runtime payload, not full host-native closure.

That means you get:

- `skills/`
- `commands/`
- `config/upstream-lock.json`
- `config/skills-lock.json` if present
- the canonical `skills/vibe/` runtime mirror

It does not automatically give you:

- host plugin provisioning
- MCP registration
- provider credential wiring
- automatic merge into Claude Code's real `settings.json`

## Manual Copy Steps

Assume your target directory is: `<TARGET_ROOT>`

1. Create the target directory layout

```bash
mkdir -p <TARGET_ROOT>/skills <TARGET_ROOT>/commands <TARGET_ROOT>/config
```

2. Copy runtime skills

```bash
cp -R ./bundled/skills/. <TARGET_ROOT>/skills/
```

3. Copy commands

```bash
cp -R ./commands/. <TARGET_ROOT>/commands/
```

4. Copy lock files

```bash
cp ./config/upstream-lock.json <TARGET_ROOT>/config/upstream-lock.json
cp ./config/skills-lock.json <TARGET_ROOT>/config/skills-lock.json
```

If `skills-lock.json` is not present, skip it.

## Host-Specific Follow-Up

### Codex

- open `~/.codex/settings.json`
- add only the fields you need under `env`
- common examples are `OPENAI_API_KEY` and `OPENAI_BASE_URL`
- do not paste secrets into chat

### Claude Code

- open `~/.claude/settings.json`
- add only the fields you need under `env`
- common examples are:
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- add `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` only when needed for the host connection
- you may use `~/.claude/settings.vibe.preview.json` as a reference, but never overwrite the real file wholesale
- do not paste secrets into chat

## Most Important Boundary

- this path does not automatically finish online provider configuration
- if `url` / `apikey` / `model` are not configured locally, the environment must not be described as online-ready
- other agents are not part of the supported surface in the current version

## When Not To Use This Path

Prefer prompt-based install when:

- you want AI to choose the correct supported host for you
- you want the scripts to run install + check
- you do not want to manually interpret local configuration instructions

Main entry:

- [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md)
