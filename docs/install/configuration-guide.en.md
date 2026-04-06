# Configuration Guide

This guide clarifies one thing only: how to finish the AI-governance advice online configuration after install.

## First, separate these two states

- `installed locally`: VibeSkills files have been installed into the target host root
- `AI governance online-ready`: the advice path has usable local credentials, model selection, and a reachable provider endpoint

The first state does not imply the second.

## What the quick check actually reads

The current quick check reads from:

1. `<target-root>/settings.json` -> `env`
2. the current shell / process environment

So:

- if the host uses a local `settings.json`, put the variables under `env`
- if the host does not use that file surface, or if you just want to validate connectivity first, use local environment variables

Do not paste secrets into chat.

## Which file you actually edit when setup is still manual

When an install guide says "configure locally", it should land on one of the real paths below instead of stopping at a vague reminder.

| Host | Real path / file | How to set it |
| --- | --- | --- |
| `codex` | `<target-root>/settings.json`, default `~/.codex/settings.json` | open the file, find or create the top-level `env` object, add `VCO_INTENT_ADVICE_*`, and add `VCO_VECTOR_DIFF_*` only when vector diff is desired |
| `claude-code` | `~/.claude/settings.json` | merge the `VCO_*` keys into the existing `env` object; do not replace the whole file |
| `cursor` | `~/.cursor/settings.json` | merge `VCO_*` keys into the real settings file; the repo may materialize a bounded minimal Vibe surface there, but it does not take over unrelated Cursor settings |
| `windsurf` | inspect `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json`; default target root is `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf` | use those files only to confirm repo-owned sidecar state; host-native login, provider, and model-permission settings still belong on the Windsurf side. If you only want to validate AI advice connectivity first, set `VCO_*` in local environment variables |
| `openclaw` | inspect `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json`; default target root is `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw` | use those files only to confirm repo-owned sidecar state; host-native login, provider, model, and editor behavior still belong on the OpenClaw side. If you only want to validate AI advice connectivity first, set `VCO_*` in local environment variables |
| `opencode` | the real host file is `~/.config/opencode/opencode.json`; the scaffold is `<target-root>/opencode.json.example` | open the real host file, compare it with the example, and copy in only the permission / command / provider structure you actually need; provider credentials and MCP trust stay host-managed on the OpenCode side |

For hosts that use an `env` object, the recommended shape is:

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

Notes:

- `VCO_VECTOR_DIFF_*` is optional; if absent, diff degrades to plain text
- legacy `OPENAI_*` values are not auto-migrated into `VCO_*`
- keep secrets in local settings files or local environment variables, never in chat

## Built-in intent advice configuration

The governance runtime now drives intent advice exclusively from the `VCO_INTENT_ADVICE_*` keys. This is the public, supported path that the quick check and routers read before making any outbound request.

### Required keys

```json
{
  "env": {
    "VCO_INTENT_ADVICE_API_KEY": "<local-api-key>",
    "VCO_INTENT_ADVICE_BASE_URL": "https://api.openai.com/v1",
    "VCO_INTENT_ADVICE_MODEL": "gpt-5.4-high"
  }
}
```

Notes:

- `VCO_INTENT_ADVICE_API_KEY`: required for all built-in advice routes
- `VCO_INTENT_ADVICE_BASE_URL`: optional; when absent, the policy/provider config dictates the default
- `VCO_INTENT_ADVICE_MODEL`: required unless overridden in `config/llm-acceleration-policy.json`
- Legacy `OPENAI_*` keys are no longer used as automatic fallbacks for intent advice; they can remain side-by-side but the runtime will not backfill them.

## Optional vector diff embeddings configuration

Vector diff embeddings are an auxiliary capability that improves diff summarization but should never block intent advice. Configure them independently using the `VCO_VECTOR_DIFF_*` keys.

### Optional keys

```json
{
  "env": {
    "VCO_VECTOR_DIFF_API_KEY": "<embedding-key>",
    "VCO_VECTOR_DIFF_BASE_URL": "https://api.openai.com/v1",
    "VCO_VECTOR_DIFF_MODEL": "text-embedding-ada-002"
  }
}
```

Notes:

- Vector diff reads these keys only when enabled in `config/llm-acceleration-policy.json`.`context.vector_diff`
- If embeddings are missing, vector diff degrades gracefully (vector_diff_status becomes `vector_diff_missing_credentials` or `vector_diff_not_configured`) but the advice path still runs.
- The vector diff keys are independent; you can point them at a different provider without affecting the intent advice configuration.

## Advanced path: policy-managed provider settings

If you already maintain provider details in the strategy files, continue to specify:

- `config/llm-acceleration-policy.json` -> `provider.base_url`
- `config/llm-acceleration-policy.json` -> `provider.model`

In that setup:

- base URL and model can still come from policy overrides
- the local credentials for that provider must sit under `VCO_INTENT_ADVICE_*`

## Where this usually goes per host

### Codex

- target root: `CODEX_HOME` or `~/.vibeskills/targets/codex`
- common location: `~/.codex/settings.json` -> `env`

### Claude Code

- target root: `CLAUDE_HOME` or `~/.vibeskills/targets/claude-code`
- common location: `~/.claude/settings.json` -> `env`

### Cursor

- target root: `CURSOR_HOME` or `~/.vibeskills/targets/cursor`
- real file: `~/.cursor/settings.json`
- common pattern: merge `env` / `VCO_*` keys into the existing settings surface; the repo may materialize a bounded minimal Vibe surface there, but it does not take over unrelated Cursor settings

### Windsurf

- target root: `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf`
- repo-side files you can inspect: `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json`
- if the host does not use `<target-root>/settings.json`, set local `VCO_*` environment variables before running the check

### OpenClaw

- target root: `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- repo-side files you can inspect: `<target-root>/.vibeskills/host-settings.json` and `<target-root>/.vibeskills/host-closure.json`
- if the host does not use `<target-root>/settings.json`, set local `VCO_*` environment variables before running the check

### OpenCode

- target root: `OPENCODE_HOME` or `~/.vibeskills/targets/opencode`
- the real host config directory remains `~/.config/opencode`
- the real file you edit manually is `~/.config/opencode/opencode.json`
- `<target-root>/opencode.json.example` is only a reference scaffold, not the live host config
- if the host does not use `<target-root>/settings.json`, set local `VCO_*` environment variables before running the check

## Quick-check commands

Run from the repo root.

### Windows

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-router-ai-connectivity-gate.ps1 -TargetRoot "<target host root>" -WriteArtifacts
```

If PowerShell 7 is already installed on your machine, you can use `pwsh` instead.

### Linux / macOS

```bash
python3 ./scripts/verify/runtime_neutral/router_ai_connectivity_probe.py --target-root "<target host root>" --write-artifacts
```

Common default target roots:

- `codex` -> `CODEX_HOME` or `~/.vibeskills/targets/codex`
- `claude-code` -> `CLAUDE_HOME` or `~/.vibeskills/targets/claude-code`
- `cursor` -> `CURSOR_HOME` or `~/.vibeskills/targets/cursor`
- `windsurf` -> `WINDSURF_HOME` or `~/.vibeskills/targets/windsurf`
- `openclaw` -> `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- `opencode` -> `OPENCODE_HOME` or `~/.vibeskills/targets/opencode`

## How to read the result

- `ok`: AI-governance advice is online
- `missing_credentials`: built-in intent-advice credentials are missing; usually add `VCO_INTENT_ADVICE_API_KEY`
- `missing_model`: the intent-advice model is missing; usually add `VCO_INTENT_ADVICE_MODEL`
- `missing_base_url`: add the provider base URL locally, or define `provider.base_url` in policy
- `provider_rejected_request`: key, model id, or endpoint compatibility is wrong
- `provider_unreachable`: network, DNS, base-url reachability, or timeout is failing
- `prefix_required`: the current policy only evaluates advice in explicit `/vibe` scope

## Owned-only uninstall cleanup

When you need to reverse an install, run `pwsh -NoProfile -File ..\..\uninstall.ps1 --host <host> --target-root <root>` or, on Linux/macOS, `bash ./uninstall.sh ...`. The uninstallers honor the ledger-first contract described in [`docs/uninstall-governance.md`](../uninstall-governance.md) and will only delete Vibe-managed surfaces recorded in the install ledger, closure manifest, or documented legacy payloads.

## Short practical conclusion

If you want the fastest path for the normal built-in intent-advice setup:

1. configure `VCO_INTENT_ADVICE_API_KEY` locally
2. add `VCO_INTENT_ADVICE_BASE_URL` only when you use a custom gateway
3. configure `VCO_INTENT_ADVICE_MODEL`
4. run the quick check

Vector diff embeddings stay optional. Configure `VCO_VECTOR_DIFF_API_KEY` / `VCO_VECTOR_DIFF_BASE_URL` / `VCO_VECTOR_DIFF_MODEL` only when you want large-diff semantic retrieval.
