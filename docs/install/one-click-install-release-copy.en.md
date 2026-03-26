# Install Entry (Single Public Entry)

This is the single public install entrypoint.

Normal users only need this page.
It routes to the four retained base install prompt docs.

## Choose Two Things

1. Confirm the host: `codex`, `claude-code`, `cursor`, `windsurf`, `openclaw`, or `opencode`
2. Confirm the action and public version:
   - install: `Full Version + Customizable Governance`
   - install: `Framework Only + Customizable Governance`
   - update: `Full Version + Customizable Governance`
   - update: `Framework Only + Customizable Governance`

Public version maps to:

- `Full Version + Customizable Governance` -> `full`
- `Framework Only + Customizable Governance` -> `minimal`

## Copy One Prompt

The four retained base prompt docs cover install / update and full / minimal.
Outside these four docs, the other pages no longer act as public install prompt entrypoints.

- [`prompts/full-version-install.en.md`](./prompts/full-version-install.en.md)
- [`prompts/framework-only-install.en.md`](./prompts/framework-only-install.en.md)
- [`prompts/full-version-update.en.md`](./prompts/full-version-update.en.md)
- [`prompts/framework-only-update.en.md`](./prompts/framework-only-update.en.md)

## Read Next Only If Needed

- Host-specific supplements:
  - [`openclaw-path.en.md`](./openclaw-path.en.md)
  - [`opencode-path.en.md`](./opencode-path.en.md)
- Framework-only command path:
  - [`minimal-path.en.md`](./minimal-path.en.md)
- More install commands and host details:
  - [`recommended-full-path.en.md`](./recommended-full-path.en.md)
  - [`manual-copy-install.en.md`](./manual-copy-install.en.md)
  - [`host-plugin-policy.en.md`](./host-plugin-policy.en.md)
- If you want to bring in your own workflows or skills afterward:
  - [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md)
  - [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md)

## About Follow-Up Configuration

- the base install can be used directly once it finishes
- if you later want online providers, MCP, host-local settings, or plugin integrations, those should be presented as optional enhancement guidance rather than mandatory blockers
- the prompt docs and references still explain truthfully which parts remain host-managed

## Quick Check After Install: Is AI Governance Configured?

If you want to quickly confirm whether the router AI governance advice path is configured, run this from the repo root:

- Windows:
  - `pwsh -NoProfile -File .\scripts\verify\vibe-router-ai-connectivity-gate.ps1 -TargetRoot "<target host root>" -WriteArtifacts`
- Linux / macOS:
  - `python3 ./scripts/verify/runtime_neutral/router_ai_connectivity_probe.py --target-root "<target host root>" --write-artifacts`

Common default roots:

- `codex` -> `~/.codex`
- `claude-code` -> `~/.claude`
- `cursor` -> `~/.cursor`
- `windsurf` -> `~/.codeium/windsurf`
- `openclaw` -> `~/.openclaw`
- `opencode` -> `~/.config/opencode`

Result hints:

- `ok`: AI governance advice is online
- `missing_credentials` / `missing_model`: local configuration is still incomplete
- `provider_rejected_request` / `provider_unreachable`: an online call was attempted, but it is not ready yet
