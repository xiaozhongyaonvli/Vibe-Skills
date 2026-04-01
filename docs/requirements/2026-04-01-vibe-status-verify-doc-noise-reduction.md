# 2026-04-01 Status And Verify Doc Noise Reduction

## Goal

继续压缩两类高频文档噪音：

1. `docs/status/` 中 dated baseline / closure 文件的可见性和阅读边界。
2. `scripts/verify/README.md` 这类过长的 verify 操作手册。

## In Scope

- 把 `docs/status/README.md` 收口成 active-only 入口。
- 把 `scripts/verify/README.md` 改成短 operator entrypoint。
- 保留常用命令、核心边界和必要的 legacy gate 说明。

## Out Of Scope

- 重写 dated status reports 正文。
- 修改 verify gates、本地脚本或 runtime 行为。
- 删除历史文件。

## Constraints

- 必须低风险，只做文档收口。
- 保留 auditability，不让历史文件失联。
- 不再在入口页堆叠完整 gate 名单或长篇专题说明。

## Acceptance Criteria

- `docs/status/README.md` 明确说明哪些文件是 active surfaces，哪些是 archival-by-default。
- `scripts/verify/README.md` 只保留最常用 quick start、关键边界和索引跳转。
- 改动后 targeted diff/grep 检查通过，没有重新引入 mirror-first 叙事。
