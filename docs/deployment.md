# Deployment

## Profiles

- `minimal`: install required runtime-core payload only
- `full`: install full vendored mirror and host-specific extras for the selected adapter mode

## Host Selector

- `codex`: official governed lane
- `claude-code`: preview scaffold lane
- `generic`: neutral runtime-core lane
- `opencode`: neutral runtime-core lane for experiments, not host-native closure

`TargetRoot` is a filesystem path.
`HostId` / `--host` is the adapter choice.
Changing the path alone does not change adapter semantics.

## Recommended Commands

### Windows

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
pwsh -File .\install.ps1 -HostId generic -Profile full
pwsh -File .\check.ps1 -HostId generic -Profile full
```

### Linux / macOS

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
bash ./install.sh --host generic --profile full
bash ./check.sh --host generic --profile full
```

## Truth Boundaries

- Only `codex` is the full governed-with-constraints lane.
- `claude-code` is scaffold + preview check, not full closure.
- `generic` and `opencode` install only runtime-core into neutral target roots.
- Provider URL / API key / model remain user-supplied host-managed inputs for non-governed lanes.

## Verification

```powershell
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
pwsh -File .\check.ps1 -HostId generic -Profile full
pwsh -File .\scripts\verify\vgo-adapter-closure-gate.ps1 -WriteArtifacts
pwsh -File .\scripts\verify\vgo-adapter-target-root-guard-gate.ps1 -WriteArtifacts
```

```bash
bash ./check.sh --host codex --profile full --deep
bash ./check.sh --host claude-code --profile full --deep
bash ./check.sh --host generic --profile full
```
