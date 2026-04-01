# 2026-04-01 Status History Index Closure

## Goal

继续收口 `docs/status/` 目录噪音，在不修改既有 dated 文件名和引用关系的前提下，增加单独的历史索引页，让 active surfaces 与 archival-by-default 材料清晰分层。

## In Scope

- 新增 `docs/status/history-index.md`，按类别整理 dated baselines、closure reports、evidence ledgers。
- 更新 `docs/status/README.md`，把历史材料入口统一回收到历史索引页。

## Out Of Scope

- 重命名或移动现有 status 文件。
- 重写 dated status 文档正文。
- 修改脚本对 `docs/status/*` 的路径引用。

## Constraints

- 必须保持现有引用稳定。
- 历史文件仍要保留可发现性和审计价值。
- 活跃入口页继续保持短、明确、低噪音。

## Acceptance Criteria

- `docs/status/README.md` 继续只暴露 active surfaces 和最小 handoff。
- `docs/status/history-index.md` 成为唯一的历史状态材料分组入口。
- 文档改动低风险，格式检查通过。
