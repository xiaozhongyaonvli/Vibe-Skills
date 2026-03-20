# One-Step Install: Copy This Into Your AI Assistant

If you do not want to study the install details yourself, the simplest path is this:

**Copy the prompt below into your AI assistant and let it handle the first install pass for you.**

## Prompt To Copy Into AI

```text
You are now my VibeSkills installation assistant.
project link：https://github.com/foryourhealth111-pixel/Vibe-Skills
Please install this repository in the current workspace and explain the outcome in plain English.

Requirements:
1. Detect whether the current system is Windows, Linux, or macOS.
2. Read `README.en.md`, `docs/quick-start.en.md`, and `docs/install/one-click-install-release-copy.en.md` before you start.
3. If the system is Windows:
   - prefer `pwsh -File .\scripts\bootstrap\one-shot-setup.ps1`
   - then run `pwsh -File .\check.ps1 -Profile full -Deep`
   - only fall back to Windows PowerShell if `pwsh` is unavailable
4. If the system is Linux or macOS:
   - run `bash ./scripts/bootstrap/one-shot-setup.sh`
   - then run `bash ./check.sh --profile full --deep`
   - explicitly tell me whether `pwsh` is available, because a Linux/macOS environment without `pwsh` should be treated as supported-with-constraints rather than fully complete
5. After installation, give me a short English summary that clearly states:
   - what is already done
   - what is still missing
   - what I still need to do manually
6. Do not pretend that host plugins, external MCP surfaces, or provider secrets were automatically configured if they were not.
7. If the final state is `manual_actions_pending`, turn the remaining manual work into a short checklist.
8. By default, recommend the most important host-managed follow-up first instead of telling me to install everything at once.
> Reminder: Do not directly reuse repository example values ​​for AI-powered intelligent governance layer configurations. When enabling this layer, users must provide and confirm the `url`, `apikey`, and `model` themselves. If AI assists in installation or generating the configuration, the prompt should clearly remind users to fill in these three items before continuing to write the configuration.
```

## What This Prompt Will Help With

In normal use, your AI assistant should:

- detect the platform
- choose the correct install path
- run the install and check commands
- tell you what is already complete
- tell you what still needs manual follow-up

You do not need to understand the whole install matrix on day one.
You only need a clean first pass.

## What It Will Not Pretend To Do

This one-step entry tries to close what the repository itself can reasonably own.

It does **not** pretend that these things are magically complete:

- every host plugin is already installed
- every external MCP surface is already connected
- provider secrets are already configured
- every enhancement lane is already fully ready

If those pieces are still missing, the correct behavior is to say so clearly.

## If You Prefer To Run Commands Yourself

Windows:

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1
pwsh -File .\check.ps1 -Profile full -Deep
```

Linux / macOS:

```bash
bash ./scripts/bootstrap/one-shot-setup.sh
bash ./check.sh --profile full --deep
```

If your goal is simply to get started, the AI prompt above is still the recommended entry.

## What To Read Next

After installation, continue with:

1. [`../quick-start.en.md`](../quick-start.en.md)
2. [`../manifesto.en.md`](../manifesto.en.md)
3. [`recommended-full-path.en.md`](./recommended-full-path.en.md)

If this is your first time here, the first two are usually enough.
