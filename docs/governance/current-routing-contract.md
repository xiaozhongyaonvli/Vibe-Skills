# Current Routing Contract

Date: 2026-05-01

## Current Model

The current Vibe-Skills routing model is:

```text
skill_candidates -> skill_routing.selected -> skill_usage.used / skill_usage.unused
```

This is the only model current user-facing docs and generated runtime outputs
should teach.

## Terms

| Term | Meaning |
| --- | --- |
| `candidate` | A skill was considered by routing. This is not a use claim. |
| `selected` | A skill was chosen into the work surface through `skill_routing.selected`. This is not a use claim. |
| `used` | A selected or loaded skill shaped an artifact and appears in `skill_usage.used` with evidence. |
| `unused` | A selected or loaded skill did not shape an artifact and appears in `skill_usage.unused`. |
| `evidence` | A stage, artifact reference, and impact summary proving material skill use. |
| `retired old-format fields` | Old routing, consultation, and dispatch fields are not current inputs, current outputs, or maintained compatibility targets. |

## Usage Proof

A skill may be reported as used only when all of these are true:

1. The skill appears in `skill_usage.used`.
2. The skill has at least one `skill_usage.evidence` record.
3. The evidence names a concrete stage and artifact impact.

Routing, selection, old consultation receipts, and old dispatch records are not
usage proof.

## Current Output Rules

Current runtime outputs should use these names:

```text
skill_candidates
skill_routing.selected
skill_usage.used
skill_usage.unused
skill_usage.evidence
```

Current runtime outputs should not teach old routing mechanisms as active
behavior.

## Retired Old-Format Fields

The following old fields are retired. Current runtime code must not use them to
infer selected skills, material skill use, or current execution ownership:

```text
legacy_skill_routing
specialist_recommendations
specialist_dispatch
stage_assistant_hints
discussion_specialist_consultation
planning_specialist_consultation
approved_consultation
consulted_units
discussion_consultation
planning_consultation
```

When current and retired fields are both present in an old artifact, current
runtime code should prefer `skill_routing` and `skill_usage` and ignore retired
fields for current behavior.

## Non-Goals

This contract does not delete old artifacts. It defines how current routing and
current usage claims should be explained and verified.
