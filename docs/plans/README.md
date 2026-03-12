# Plans

- Up: [`../README.md`](../README.md)

## What Lives Here

`docs/plans/` 保存时间绑定的执行计划、triage、closure 报告、wave horizon 和阶段性设计稿。

这里的职责是 current-entry 和 background-entry，不承担 runtime truth surface。运行态与 proof 请回到 `docs/status/`。

## Start Here

### Current Entry

- [`2026-03-11-vco-repo-simplification-remediation-plan.md`](2026-03-11-vco-repo-simplification-remediation-plan.md): 当前唯一主执行计划；以“先保行为、再收结构”为硬约束，按 `α -> ω` 推进 repo 收口。

### Supporting Current

- [`2026-03-11-node-zombie-guardian-implementation-plan.md`](2026-03-11-node-zombie-guardian-implementation-plan.md): 当前阶段卫生与僵尸 Node 防误杀实现计划；服务于每轮 batch 的 phase-end cleanup。
- [`2026-03-08-repo-cleanliness-batch2-4-triage.md`](2026-03-08-repo-cleanliness-batch2-4-triage.md): 当前 cleanup-first 剩余工作集拆分、stop rules 与批次顺序。

### Runtime / Proof Handoff

- [`../status/README.md`](../status/README.md): 当前运行态、proof 入口与阶段回执
- [`../status/current-state.md`](../status/current-state.md): 当前 closure batch 的 runtime summary
- [`../status/non-regression-proof-bundle.md`](../status/non-regression-proof-bundle.md): minimum closure proof contract

## Background Entry

- [`2026-03-09-batch0-9-closure-report.md`](2026-03-09-batch0-9-closure-report.md): Batch 0-9 的执行收口报告与剩余 governed backlog。
- [`2026-03-08-repo-full-cleanup-master-plan.md`](2026-03-08-repo-full-cleanup-master-plan.md): cleanup umbrella plan；保留为历史母纲与背景材料。
- [`2026-03-07-repo-cleanliness-next-wave-plan.md`](2026-03-07-repo-cleanliness-next-wave-plan.md): repo cleanliness 先行方案与后续整理原则。
- [`2026-03-07-nested-bundled-root-parity-governance-plan.md`](2026-03-07-nested-bundled-root-parity-governance-plan.md): nested parity 与 version topology 的历史治理计划。

## Wave Horizons

- [`2026-03-08-vco-wave121-140-operatorized-value-extraction-plan.md`](2026-03-08-vco-wave121-140-operatorized-value-extraction-plan.md): 最新 continuation horizon。
- [`2026-03-08-vco-wave101-120-value-extraction-plan.md`](2026-03-08-vco-wave101-120-value-extraction-plan.md): 上一阶段 continuation horizon。
- Older wave materials remain here as historical background:
  - `2026-03-07-vco-wave83-100-execution-plan.md`
  - `2026-03-07-vco-wave83-100-execution-status.md`
  - `2026-03-07-vco-wave64-82-execution-plan.md`
  - `2026-03-07-vco-wave40-63-execution-plan.md`
  - `2026-03-07-vco-deep-value-extraction-drift-closure-plan.md`
  - `2026-03-07-vco-full-spectrum-integration-plan.md`

## Design Spikes

- [`2026-03-04-gpt52-llm-acceleration-design.md`](2026-03-04-gpt52-llm-acceleration-design.md)
- [`2026-03-04-turbomax-vector-context-design.md`](2026-03-04-turbomax-vector-context-design.md)

## Rules

- `Current Entry` 只保留当前仍在驱动执行的少量文档；新增 active plan 时，优先替换而不是继续扩容
- `Supporting Current` 只保留服务于当前主计划的少量辅助材料，不与主计划并列为同级入口
- runtime truth 与 proof contract 不在 `plans/` 内重复维护，只通过 `Runtime / Proof Handoff` 回指 `docs/status/`
- wave horizon、closure report、历史母纲默认进入 background 区，不与当前执行入口并列
- 阶段性设计稿保留在 `plans/`，除非已经升级为长期治理正文，才迁入 root `docs/`
- 新增 `docs/plans/*.md` 后，必须更新本索引，并在叶子文档中保留返回 [`../README.md`](../README.md) 的导航闭环
