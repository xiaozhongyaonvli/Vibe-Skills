[English](./README.en.md)

# VibeSkills

```text
             VibeSkills
          cute octopus core

        skills   plugins   workflows
            \       |       /
             \      |      /
              \     |     /
               [ governed ]
              /   runtime  \
             /      |       \
      routing   verification   traceability
```

> 不是另一个 skills 仓库。它是一个把调用、治理、验证与留痕整合在一起的 AI agent system。

`VibeSkills` 是你看到的公开名字，`VCO` 是它背后的 governed runtime。

当越来越多优秀的 skills、插件、工作流和 agent 项目同时出现时，问题往往不再是“没有能力”，而是“能力太多、入口太散、彼此冲突，而且一旦开跑就容易失控”。

`VibeSkills` 想解决的不是“再加一个工具”。
它想解决的是另一件更现实的事：把强但分散的能力收进同一个系统里，让 AI 更容易调用对的能力，更稳定地按对的流程做事，更少把人拖进黑盒。

## Capability Snapshot

| Scale                          | Runtime              | Governance                                 |
| ------------------------------ | -------------------- | ------------------------------------------ |
| `340` bundled skills           | `dual-layer routing` | `129` config-backed policies and contracts |
| `19` governed upstream sources | `governed runtime`   | `verification and cleanup`                 |

`VibeSkills` 展示的不是静态目录，而是一套已经把能力规模、执行约束和治理密度压进同一平面的 AI system。

## 为什么它会让人立刻感到不一样

很多 skills 仓库在回答一个问题：`这里有什么？`

`VibeSkills` 更在意的是另外几个问题：

- 现在该调用什么，而不是让你自己翻完整个技能表
- 应该先做什么，而不是让 AI 直接跳进执行
- 哪些能力可以安全组合，哪些地方必须设边界
- 完成之后怎么验证、怎么留痕、怎么避免长期黑盒化

它不是把能力堆得更多。
它是在把“调用、治理、验证、回看”整合成一个真正能工作的系统。

## 它真正解决的痛点

如果你已经在重度使用 AI，大概率已经遇到过这些问题：

- skills 太多，不知道当前场景到底该用哪个
- 项目、插件、工作流互相重叠，也互相冲突
- AI 没澄清需求就直接开做，速度很快，方向却不稳
- 做完之后没有验证、没有证据、没有回退面
- 随着使用变深，整个工作流越来越像一个没人说得清的黑盒

`VibeSkills` 不是假装这些问题不存在。
它的价值就在于正面处理这些问题。

## 它是怎么工作的

你可以把它理解成三层：

### 1. 智能路由

在合适的场景下，AI 不需要你显式记住“这次该调用哪个 skill”。

`VibeSkills` 会把逻辑路由和 AI 智能路由结合起来，尽量把合适的能力放到合适的场景里，让调用更自然，而不是靠你手动背技能表。

### 2. 受管工作流

它不只是在“调工具”。
它更关心工作怎么做才稳定。

所以这套系统会尽量把需求澄清、确认、执行、验证、回顾、留痕这些步骤收进统一流程里，避免 AI 一上来就黑盒式开跑。

### 3. 整合能力

这里不只有 skills。

还有插件、项目、工作流设计、AI 规范、安全边界、长期维护经验，以及我自己在实践里踩过的坑。
`VCO` 负责把这些能力组织成一个更统一的运行时，而不是让它们继续散落在不同角落里。

## 它适合谁

`VibeSkills` 主要适合这几类人：

- 想让 AI 更稳定地帮自己做事的普通用户
- 已经在重度使用 AI / Agent / 自动化的进阶用户
- 想把 AI 工作流做得更规范、更可维护的个人或小团队
- 已经厌倦“技能太多但不好用”的人

如果你只是想找一个单点工具，这个仓库可能不是最轻的选择。
如果你想把 AI 用得更稳、更顺、更长期，它会更有意义。

## 开始了解它

如果你想先快速理解这套系统，再决定走哪条路径：

- [`docs/quick-start.md`](./docs/quick-start.md)
- [`docs/manifesto.md`](./docs/manifesto.md)

如果你已经准备开始安装，再进入一步式安装入口：

- [`docs/install/one-click-install-release-copy.md`](./docs/install/one-click-install-release-copy.md)

如果你已经是重度用户，想进一步看更完整的安装与路径说明：

- [`docs/install/recommended-full-path.md`](./docs/install/recommended-full-path.md)
- [`docs/cold-start-install-paths.md`](./docs/cold-start-install-paths.md)

## 一句话收尾

`VibeSkills` 想做的不是把项目说得更玄。
它想做的是把真实工作里最容易失控的那一部分，变成一个更可调用、更可治理、更可验证、也更可长期维护的 AI 系统。
