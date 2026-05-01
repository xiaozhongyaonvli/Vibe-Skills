from __future__ import annotations

from typing import Any

from .router_contract_support import candidate_name_score, keyword_ratio, normalize_text


def normalize_candidate_keys(values: list[Any] | None) -> set[str]:
    return {
        normalize_text(value)
        for value in (values or [])
        if normalize_text(value)
    }


def get_pack_skill_candidates(pack: dict[str, Any]) -> list[str]:
    direct_candidates = [
        str(item).strip()
        for item in (pack.get("skill_candidates") or [])
        if str(item).strip()
    ]
    if direct_candidates:
        return list(dict.fromkeys(direct_candidates))

    legacy_candidates: list[str] = []
    for key in ("route_authority_candidates", "stage_assistant_candidates"):
        legacy_candidates.extend(
            str(item).strip()
            for item in (pack.get(key) or [])
            if str(item).strip()
        )
    return list(dict.fromkeys(legacy_candidates))


def get_pack_default_candidate(pack: dict[str, Any], task_type: str, filtered_candidates: list[str], all_candidates: list[str]) -> str | None:
    defaults = pack.get("defaults_by_task") or {}
    preferred = normalize_text(defaults.get(task_type))
    if preferred:
        for candidate in filtered_candidates:
            if normalize_text(candidate) == preferred:
                return candidate
        for candidate in all_candidates:
            if normalize_text(candidate) == preferred:
                return candidate
    return filtered_candidates[0] if filtered_candidates else (all_candidates[0] if all_candidates else None)


INTERNAL_CANDIDATE_USABLE = "_candidate_usable"
INTERNAL_LEGACY_ROLE = "_legacy_role"
INTERNAL_SELECTION_USABLE = "_selection_usable"
INTERNAL_LEGACY_STAGE_ASSISTANTS = "_legacy_stage_assistant_candidates"


def public_candidate_row(row: dict[str, Any]) -> dict[str, Any]:
    public = dict(row)
    for key in (
        INTERNAL_CANDIDATE_USABLE,
        INTERNAL_LEGACY_ROLE,
        "route_authority_eligible",
        "legacy_role",
    ):
        public.pop(key, None)
    return public


def public_candidate_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [public_candidate_row(row) for row in rows]


def candidate_is_usable(row: dict[str, Any]) -> bool:
    if INTERNAL_CANDIDATE_USABLE in row:
        return bool(row[INTERNAL_CANDIDATE_USABLE])
    return bool(row.get("route_authority_eligible", True))


def candidate_legacy_role(row: dict[str, Any]) -> str:
    if INTERNAL_LEGACY_ROLE in row:
        return str(row[INTERNAL_LEGACY_ROLE])
    return str(row.get("legacy_role") or "skill_candidate")


def select_pack_candidate(
    prompt_lower: str,
    candidates: list[str],
    task_type: str,
    requested_canonical: str | None,
    skill_keyword_index: dict[str, Any],
    routing_rules: dict[str, Any],
    pack: dict[str, Any],
    candidate_selection_config: dict[str, Any],
) -> dict[str, Any]:
    if not candidates:
        return {
            "selected": None,
            "score": 0.0,
            "reason": "no_candidates",
            "ranking": [],
            "top1_top2_gap": 0.0,
            "filtered_out_by_task": [],
        }

    normalized_candidates = {
        normalize_text(candidate): candidate
        for candidate in candidates
        if normalize_text(candidate)
    }
    requested_candidate = normalized_candidates.get(requested_canonical) if requested_canonical else None

    selection_cfg = skill_keyword_index.get("selection") or {}
    selection_weights = selection_cfg.get("weights") or {}
    weight_keyword = float(selection_weights.get("keyword_match", 0.85))
    weight_name = float(selection_weights.get("name_match", 0.15))
    fallback_min = float(selection_cfg.get("fallback_to_first_when_score_below", 0.15))

    positive_bonus = float(candidate_selection_config.get("rule_positive_keyword_bonus", 0.2))
    negative_penalty = float(candidate_selection_config.get("rule_negative_keyword_penalty", 0.25))
    canonical_bonus = float(candidate_selection_config.get("canonical_for_task_bonus", 0.12))

    rules = (routing_rules.get("skills") or {}) if routing_rules else {}
    rules_by_skill = {
        normalize_text(skill): rule
        for skill, rule in rules.items()
        if normalize_text(skill)
    }
    filtered_candidates: list[str] = []
    blocked_by_task: list[str] = []
    for candidate in candidates:
        rule = rules_by_skill.get(normalize_text(candidate)) or {}
        task_allow = [normalize_text(item) for item in (rule.get("task_allow") or [])]
        if not task_allow or task_type in task_allow:
            filtered_candidates.append(candidate)
        else:
            blocked_by_task.append(candidate)

    default_candidate = get_pack_default_candidate(pack, task_type, filtered_candidates, candidates)
    if not filtered_candidates:
        if requested_candidate:
            return {
                "selected": requested_candidate,
                "score": 1.0,
                "reason": "requested_skill",
                "ranking": public_candidate_rows([
                    {
                        "skill": requested_candidate,
                        "score": 1.0,
                        "keyword_score": 1.0,
                        "name_score": 1.0,
                        "positive_score": 1.0,
                        "negative_score": 0.0,
                        "canonical_for_task_hit": 1.0,
                        INTERNAL_CANDIDATE_USABLE: True,
                        INTERNAL_LEGACY_ROLE: "explicit_request",
                    }
                ]),
                "top1_top2_gap": 1.0,
                "filtered_out_by_task": blocked_by_task,
                INTERNAL_SELECTION_USABLE: True,
                "relevance_score": 1.0,
                INTERNAL_LEGACY_STAGE_ASSISTANTS: [],
            }
        fallback = default_candidate or candidates[0]
        return {
            "selected": fallback,
            "score": 0.0,
            "reason": "fallback_task_default_after_task_filter" if default_candidate else "fallback_first_candidate_after_task_filter",
            "ranking": [],
            "top1_top2_gap": 0.0,
            "filtered_out_by_task": blocked_by_task,
            INTERNAL_SELECTION_USABLE: True,
            "relevance_score": 0.0,
            INTERNAL_LEGACY_STAGE_ASSISTANTS: [],
        }

    authority_allowlist = normalize_candidate_keys(pack.get("route_authority_candidates"))
    stage_assistant_allowlist = normalize_candidate_keys(pack.get("stage_assistant_candidates")) if "stage_assistant_candidates" in pack else set()
    default_candidate = get_pack_default_candidate(pack, task_type, filtered_candidates, candidates)

    scored: list[dict[str, Any]] = []
    keywords_by_skill = skill_keyword_index.get("skills") or {}
    keywords_by_skill_normalized = {
        normalize_text(skill): entry
        for skill, entry in keywords_by_skill.items()
        if normalize_text(skill)
    }
    for ordinal, candidate in enumerate(filtered_candidates):
        candidate_key = normalize_text(candidate)
        skill_entry = keywords_by_skill_normalized.get(candidate_key) or {}
        keyword_score = keyword_ratio(prompt_lower, skill_entry.get("keywords") or [])
        name_score = candidate_name_score(prompt_lower, candidate)

        rule = rules_by_skill.get(candidate_key) or {}
        positive_score = keyword_ratio(prompt_lower, rule.get("positive_keywords") or [])
        negative_score = keyword_ratio(prompt_lower, rule.get("negative_keywords") or [])
        canonical_for_task = [normalize_text(item) for item in (rule.get("canonical_for_task") or [])]
        canonical_hit = 1.0 if task_type in canonical_for_task else 0.0
        use_eligible = True
        requires_positive_keyword_match = bool(rule.get("requires_positive_keyword_match"))
        if use_eligible and requires_positive_keyword_match and positive_score <= 0:
            use_eligible = False
        legacy_role = "skill_candidate"
        if candidate_key in authority_allowlist:
            legacy_role = "route_authority"
        elif candidate_key in stage_assistant_allowlist:
            legacy_role = "stage_assistant"

        score = (
            (weight_keyword * keyword_score)
            + (weight_name * name_score)
            + (positive_bonus * positive_score)
            - (negative_penalty * negative_score)
            + (canonical_bonus * canonical_hit)
        )
        score = round(max(0.0, min(1.0, score)), 4)
        scored.append(
            {
                "skill": candidate,
                "score": score,
                "keyword_score": round(keyword_score, 4),
                "name_score": round(name_score, 4),
                "positive_score": round(positive_score, 4),
                "negative_score": round(negative_score, 4),
                "canonical_for_task_hit": round(canonical_hit, 4),
                INTERNAL_CANDIDATE_USABLE: use_eligible,
                INTERNAL_LEGACY_ROLE: legacy_role,
                "requires_positive_keyword_match": requires_positive_keyword_match,
                "ordinal": ordinal,
            }
        )

    ranked_all = sorted(scored, key=lambda row: (-row["score"], -row["keyword_score"], -row["positive_score"], row["ordinal"]))
    usable_ranked = [row for row in ranked_all if candidate_is_usable(row)]
    stage_assistant_ranked = [
        row
        for row in ranked_all
        if candidate_legacy_role(row) == "stage_assistant"
    ]

    overall_top = ranked_all[0]
    top = usable_ranked[0] if usable_ranked else None
    second = usable_ranked[1] if len(usable_ranked) > 1 else None
    gap = round(max(0.0, float(top["score"]) - float(second["score"] if second else 0.0)), 4) if top else 0.0

    if requested_candidate:
        return {
            "selected": requested_candidate,
            "score": 1.0,
            "reason": "requested_skill",
            "ranking": public_candidate_rows([
                {
                    "skill": requested_candidate,
                    "score": 1.0,
                    "keyword_score": 1.0,
                    "name_score": 1.0,
                    "positive_score": 1.0,
                    "negative_score": 0.0,
                    "canonical_for_task_hit": 1.0,
                    INTERNAL_CANDIDATE_USABLE: True,
                    INTERNAL_LEGACY_ROLE: "explicit_request",
                }
            ]),
            "top1_top2_gap": 1.0,
            "filtered_out_by_task": blocked_by_task,
            INTERNAL_SELECTION_USABLE: True,
            "relevance_score": 1.0,
            INTERNAL_LEGACY_STAGE_ASSISTANTS: public_candidate_rows([
                row for row in stage_assistant_ranked if row.get("skill") != requested_candidate
            ][:4]),
        }

    if not top:
        return {
            "selected": None,
            "score": 0.0,
            "reason": "no_usable_candidate",
            "ranking": [],
            "top1_top2_gap": 0.0,
            "filtered_out_by_task": blocked_by_task,
            INTERNAL_SELECTION_USABLE: False,
            "relevance_score": float(overall_top["score"]),
            INTERNAL_LEGACY_STAGE_ASSISTANTS: public_candidate_rows(stage_assistant_ranked[:4]),
        }

    if top["score"] < fallback_min:
        default_row = next((row for row in usable_ranked if row["skill"] == default_candidate), None) if default_candidate else None
        fallback = default_candidate if default_row else top["skill"]
        fallback_row = default_row or top
        return {
            "selected": fallback,
            "score": float(fallback_row["score"]),
            "reason": "fallback_task_default" if default_row else "fallback_first_candidate",
            "ranking": public_candidate_rows(usable_ranked[:6]),
            "top1_top2_gap": gap,
            "filtered_out_by_task": blocked_by_task,
            INTERNAL_SELECTION_USABLE: True,
            "relevance_score": float(overall_top["score"]),
            INTERNAL_LEGACY_STAGE_ASSISTANTS: public_candidate_rows([
                row for row in stage_assistant_ranked if row.get("skill") != fallback
            ][:4]),
        }

    return {
        "selected": top["skill"],
        "score": float(top["score"]),
        "reason": "keyword_ranked",
        "ranking": public_candidate_rows(usable_ranked[:6]),
        "top1_top2_gap": gap,
        "filtered_out_by_task": blocked_by_task,
        INTERNAL_SELECTION_USABLE: True,
        "relevance_score": float(overall_top["score"]),
        INTERNAL_LEGACY_STAGE_ASSISTANTS: public_candidate_rows([
            row for row in stage_assistant_ranked if row.get("skill") != top.get("skill")
        ][:4]),
    }
