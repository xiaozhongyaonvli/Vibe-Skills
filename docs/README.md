# VCO Docs

`docs/` 是 VCO 的文档层 landing surface。这里现在按三段式分流：

- `Current Entry`: 从哪里继续当前整改批次；
- `Runtime Entry`: 去哪里读取当前运行态、proof 和阶段回执；
- `Background / Governance Entry`: 去哪里读取长期治理正文与稳定 SOP。

## Start Here

### Current Entry

- [`plans/README.md`](plans/README.md): 当前 active plan、支撑性当前材料、历史 wave 规划与 closure 报告入口
- [`plans/2026-03-11-vco-repo-simplification-remediation-plan.md`](plans/2026-03-11-vco-repo-simplification-remediation-plan.md): 当前整改主计划；它是执行入口，不是长期治理合同

### Runtime Entry

- [`status/README.md`](status/README.md): 当前真实状态、proof 入口、阻塞项与阶段回执总索引
- [`status/current-state.md`](status/current-state.md): 当前批次的 artifact-backed runtime summary
- [`status/non-regression-proof-bundle.md`](status/non-regression-proof-bundle.md): minimum closure proof contract
- [`releases/README.md`](releases/README.md): current governed release surface and historical release packetization

### Background / Governance Entry

- [`docs-information-architecture.md`](docs-information-architecture.md): `docs/` 目录语义、索引规则、长期维护边界
- [`architecture.md`](architecture.md): VCO 总体结构、边界与主执行面
- [`repo-cleanliness-governance.md`](repo-cleanliness-governance.md): canonical / mirror / runtime / archive 的 cleanliness contract
- [`version-packaging-governance.md`](version-packaging-governance.md): canonical / bundled / nested / installed runtime 的 packaging topology
- [`runtime-freshness-install-sop.md`](runtime-freshness-install-sop.md): install -> freshness -> coherence 的 operator SOP
- [`output-artifact-boundary-governance.md`](output-artifact-boundary-governance.md): `outputs/**` 与 `references/fixtures/**` 的长期边界

## Cross-Layer Handoff

- [`../config/index.md`](../config/index.md): machine-readable policy, routing, packaging, and cleanliness surface
- [`../scripts/README.md`](../scripts/README.md): governance, verify, router, and common script entrypoints
- [`../references/index.md`](../references/index.md): contracts, matrices, ledgers, fixtures, and overlays

## Secondary Stable Surfaces

- [`compatibility-matrix.md`](compatibility-matrix.md): 兼容性边界与差异面
- [`observability-consistency-governance.md`](observability-consistency-governance.md): 可观测性与一致性治理
- [`blackbox-probe-and-enhancement-playbook.md`](blackbox-probe-and-enhancement-playbook.md): blackbox probing / semantic enhancement 的统一工程手册
- [`external-tooling/README.md`](external-tooling/README.md): 外部 tooling / provider / MCP 边界说明

## Rules

- root `docs/*.md` 只放长期治理正文、集成说明和稳定 operator SOP，不把 dated plan / batch report 升级成 canonical contract
- `docs/plans/` 负责当前执行入口与时间绑定计划；`docs/status/` 负责当前运行态与 proof；`docs/releases/` 负责 current release surface 与 release history
- `status/current-state.md` 只做 artifact-backed 状态摘要；truth source 在 `outputs/verify/**` 与运行态回执中，而不是这份文档本身
- 新增 root 级治理正文时，必须更新本索引；新增时间绑定材料时，更新对应子目录的 `README.md` 即可
