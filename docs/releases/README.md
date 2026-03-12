# Releases

- Up: [`../README.md`](../README.md)

## What Lives Here

This directory stores governed VCO release notes and the minimum runtime-facing navigation needed to cut or verify a release.

## Start Here

### Current Release Surface

- [`v2.3.30.md`](v2.3.30.md): Wave31-39 deep extraction / drift closure release

### Release Runtime / Proof Handoff

- [`../runtime-freshness-install-sop.md`](../runtime-freshness-install-sop.md): install, freshness, and coherence SOP
- [`../../scripts/verify/gate-family-index.md`](../../scripts/verify/gate-family-index.md): gate family navigation and typical run order
- [`../../scripts/verify/README.md`](../../scripts/verify/README.md): verify surface entrypoint
- [`../status/non-regression-proof-bundle.md`](../status/non-regression-proof-bundle.md): minimum closure proof contract

## Recent Governed Releases

- [`v2.3.30.md`](v2.3.30.md) — 2026-03-07 — Wave31-39 deep extraction / drift closure
- [`v2.3.29.md`](v2.3.29.md) — 2026-03-07 — Wave19-30 memory / browser / desktop / prompt / release cut closure
- [`v2.3.28.md`](v2.3.28.md) — 2026-03-05 — TurboMax / vector-first context / CUA / prompt asset boost / academic deliverable routing

Older release notes remain in this directory as historical version records, but they are not part of the active release surface.

## Historical Packetization

- [`wave15-18-release-packet.md`](wave15-18-release-packet.md) — historical packetization artifact, not the current release-note format

## Release Operator Entry

Canonical release cut command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\governance\release-cut.ps1 -RunGates
```

## Stop-Ship Families

Exact script names live in the gate-family index. At the README level, releases should be understood through families rather than giant flat lists:

- topology and integrity: version consistency, version packaging, config parity, nested bundled parity, mirror edit hygiene, BOM/frontmatter integrity
- runtime and install coherence: installed runtime freshness, release/install/runtime coherence
- cleanliness and readiness: repo cleanliness, wave board readiness, capability dedup, adaptive routing readiness, upstream value ops

## Extended Release Trains

Use the gate-family index for the exact scripts. The extended trains stay grouped here by governed concern:

- Wave64-82 extensions: memory runtime, browser / desktop / document / connector scorecards, cross-plane replay, ops cockpit, rollback drill, release-train closure
- Wave83-100 extensions: gate reliability, eval quality, candidate / role / subagent / discovery governance, capability lifecycle, sandbox simulation, release evidence bundle, bounded rollout, upstream re-audit closure

## Rules

- `docs/releases/README.md` 是 release 面的导航页，不承担逐 gate 逐脚本的完整枚举职责
- 当前 release surface、proof handoff、历史 packetization 必须分层展示，不再混成单一入口
- 具体 gate 名称、顺序和 family 归属以 [`../../scripts/verify/gate-family-index.md`](../../scripts/verify/gate-family-index.md) 为准
- release note 一文一版，文件名保持 `v<version>.md`
- 历史 release packet 与当前 versioned release note 分层展示，不在当前 release surface 并列暴露
