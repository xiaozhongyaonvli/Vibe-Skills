# OpenClaw Install and Use Guide

This document summarizes the most common commands, default target root, and follow-up notes for installing VibeSkills into OpenClaw.

## Why This Guide Exists

- the generic install prompts can already install `openclaw`
- this guide does not replace the generic install prompts; it expands OpenClaw-specific details
- it is split out because OpenClaw also needs clearer coverage of its default target root, attach / copy / bundle paths, and host-local boundaries, which would make the common install docs too noisy

## Default Install Information

- default target root: `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- default install style: one-shot setup + check
- host-local configuration still stays on the OpenClaw side

## Manual Settings and Sidecar Paths

When a follow-up step says "configure OpenClaw locally", use the paths below explicitly:

- repo-owned sidecar state: `<target-root>/.vibeskills/host-settings.json`
- repo-owned closure state: `<target-root>/.vibeskills/host-closure.json`
- default `<target-root>`: `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`

How to interpret them:

- inspect `host-settings.json` and `host-closure.json` to confirm what the repository materialized
- do not invent an undocumented `~/.openclaw/settings.json` contract in Vibe-Skills docs
- continue to configure login, provider credentials, model permissions, and editor-specific behavior on the OpenClaw side

## Common Install Paths

### Attach Path

Goal: connect and validate an existing OpenClaw root.

Example:

```bash
bash ./check.sh --host openclaw --target-root "${OPENCLAW_HOME:-$HOME/.vibeskills/targets/openclaw}" --profile full --deep
```

### Copy Path

Goal: copy the repo-distributed content into `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw` through the install entrypoint.

Example:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host openclaw --profile full
bash ./check.sh --host openclaw --profile full --deep
```

### Bundle Path

Goal: consume the OpenClaw distribution package through distribution manifests.

Manifest entrypoints:

- `dist/host-openclaw/manifest.json`
- `dist/manifests/vibeskills-openclaw.json`

## Current Focus

- keep the target root consistent as `OPENCLAW_HOME` or `~/.vibeskills/targets/openclaw`
- focus on install, validation, and distribution of the repo-distributed content
- keep host-local configuration on the OpenClaw side

## Contract Sources

If you need the deeper adapter contract or distribution references, continue with:

- `adapters/index.json`
- `adapters/openclaw/host-profile.json`
- `adapters/openclaw/closure.json`
- `adapters/openclaw/settings-map.json`
