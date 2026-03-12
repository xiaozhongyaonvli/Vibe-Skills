# Scripts

`scripts/` 是 VCO 的 operator surface。这个索引只负责把操作者带到正确的脚本入口，不承担 closure proof 合同或长期 reference 导航。

## Start Here

### Operator Entrypoints

- [`governance/README.md`](governance/README.md): human-run operator surface for sync, rollout, release, audit, and policy probes
- [`verify/README.md`](verify/README.md): verify surface entrypoint and canonical run order
- [`verify/gate-family-index.md`](verify/gate-family-index.md): verify family map and evidence-producing run order
- [`common/README.md`](common/README.md): shared helper API, UTF-8 no-BOM write rules, and execution-context helpers
- [`router/README.md`](router/README.md): router decision surface and module layout
- [`overlay/README.md`](overlay/README.md): overlay suggestion surface
- [`verify/fixtures/README.md`](verify/fixtures/README.md): mock, pilot, and fixture navigation for verify flows

### Cross-Layer Handoff

当你已经离开“该运行哪个脚本”的问题，而需要进入合同或证据层时，切换到：

- [`../docs/status/non-regression-proof-bundle.md`](../docs/status/non-regression-proof-bundle.md): minimum closure proof contract
- [`../references/index.md`](../references/index.md): long-lived contracts, registries, ledgers, and reference playbooks

## Directory Roles

| Path | Role | Notes |
| --- | --- | --- |
| `scripts/governance/` | operator entrypoints | rollout, release, mirror, policy, and audit commands |
| `scripts/verify/` | executable gates | stop-ship, advisory, plane, release, and closure families |
| `scripts/common/` | shared primitives | UTF-8 no BOM, execution-context, parity, and wave-runner helpers |
| `scripts/router/` | router helpers | route probing, pack routing, and keyword audit support |
| `scripts/overlay/` | overlay helpers | advice-first overlay and provider suggestion helpers |
| `scripts/bootstrap/`, `scripts/setup/` | environment bootstrap | install, setup, and compatibility helpers |
| `scripts/research/`, `scripts/learn/` | support surfaces | auxiliary surfaces, not the minimal cleanup proof bundle |

## Navigation Boundary

- This page owns operator navigation inside `scripts/`.
- [`verify/gate-family-index.md`](verify/gate-family-index.md) owns verify-family grouping and typical evidence-producing run order.
- [`../docs/status/non-regression-proof-bundle.md`](../docs/status/non-regression-proof-bundle.md) owns the minimum closure proof contract.
- [`../references/index.md`](../references/index.md) owns long-lived contracts, registries, ledgers, and reference playbooks.

## Rules

- topology-aware scripts must be run from the canonical repo root, not from a mirror or installed runtime copy
- mirror or packaging changes must be followed by the relevant verify gates
- shared logic belongs in `scripts/common/`, not duplicated ad hoc in one-off scripts
- research helpers may depend on external corpora, but those dependencies must stay explicit and parameterizable
