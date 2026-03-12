# VCO Status

`docs/status/` 是 `docs/` 层的 runtime-entry surface。这里回答三件事：

1. 现在仓库的真实状态是什么；
2. 当前收口批次在推进什么；
3. 哪些能力在 closure 期间绝不能退化。

## Start Here

### Runtime Summary

- [`current-state.md`](current-state.md): 唯一 live 状态入口；只保留 artifact-backed 摘要、阻塞项和下一跳 operator handoff
- [`roadmap.md`](roadmap.md): 当前批次顺序、exit conditions 和后续 batch 编排

### Batch Receipts

- [`operator-dry-run.md`](operator-dry-run.md): 最近一次阶段收尾 wrapper 的 operator 回执
- [`closure-audit.md`](closure-audit.md): 当前 closure batch 的完成面、未完成面与禁止误判项

### Guardrails / Proof / Transitional Baselines

- [`protected-capability-baseline.md`](protected-capability-baseline.md): closure 阶段的“禁止退化”护栏矩阵；定义哪些 surface 在清理期间必须先证明、再改动
- [`non-regression-proof-bundle.md`](non-regression-proof-bundle.md): 当前 cleanup 的最小 proof contract
- [`path-dependency-census.md`](path-dependency-census.md): 过渡期 blocker map；只说明当前还不能盲删或盲搬的依赖簇
- [`repo-cleanliness-baseline.md`](repo-cleanliness-baseline.md): dated inventory baseline；用于衡量改善 delta，不是 live dashboard

## Cross-Layer Handoff

- [`../README.md`](../README.md): docs 三段式总入口
- [`../plans/README.md`](../plans/README.md): 当前执行计划与历史背景材料
- [`../../scripts/README.md`](../../scripts/README.md): operator script surface
- [`../../scripts/verify/gate-family-index.md`](../../scripts/verify/gate-family-index.md): verify family navigation and typical run order

## Rules

- `current-state.md` 是 status 面的唯一摘要页；其数字与 PASS / FAIL 结论必须回指 `outputs/verify/**` 或运行态回执，而不是人工重复抄写
- `operator-dry-run.md` 与 `closure-audit.md` 是批次收据，只保留最近、可信、可复查的一份
- supporting baselines 只允许承担三种角色：guardrail、proof contract、transitional blocker map；凡是演化成长期稳定合同的内容，都应迁回 root `docs/` 或 `references/`
- `repo-cleanliness-baseline.md` 这类 dated baseline 必须显式区分“冻结快照”和“当前现况”；当前现况只以最新 gate receipt 为准
- 历史 closure report / batch report 继续保留在 [`../plans/README.md`](../plans/README.md)，不在这里累积流水
