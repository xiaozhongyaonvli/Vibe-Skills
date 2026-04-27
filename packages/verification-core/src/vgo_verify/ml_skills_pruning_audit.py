#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ML_KEYWORDS = {
    "machine learning",
    "ml",
    "sklearn",
    "scikit",
    "classification",
    "regression",
    "clustering",
    "feature",
    "training",
    "model evaluation",
    "cross validation",
    "deep learning",
    "transformers",
    "time series",
    "forecast",
    "anomaly",
    "机器学习",
    "模型",
    "分类",
    "回归",
    "聚类",
    "特征",
    "训练",
    "预测",
    "评估",
}

SPECIALIST_DEFER_SKILLS = {
    "shap",
    "umap-learn",
    "statsmodels",
    "tensorboard",
    "weights-and-biases",
    "transformers",
    "torch-geometric",
    "stable-baselines3",
    "timesfm-forecasting",
    "scikit-survival",
    "deepchem",
    "torchdrug",
}

OWNER_SKILLS = {
    "scikit-learn",
    "ml-pipeline-workflow",
    "exploratory-data-analysis",
    "ml-data-leakage-guard",
    "LQF_Machine_Learning_Expert_Guide",
    "statistical-analysis",
    "statsmodels",
    "aeon",
}

DEFAULT_REPLACEMENTS = {
    "anomaly-detector": "scikit-learn",
    "confusion-matrix-generator": "scikit-learn",
    "correlation-analyzer": "exploratory-data-analysis",
    "data-normalization-tool": "preprocessing-data-with-automated-pipelines",
    "data-quality-checker": "exploratory-data-analysis",
    "engineering-features-for-machine-learning": "preprocessing-data-with-automated-pipelines",
    "evaluating-machine-learning-models": "scikit-learn",
    "feature-importance-analyzer": "shap",
    "regression-analysis-helper": "scikit-learn",
    "running-clustering-algorithms": "scikit-learn",
    "training-machine-learning-models": "scikit-learn",
}

CSV_FIELDS = [
    "skill_id",
    "category",
    "current_pack",
    "current_role",
    "lines",
    "has_scripts",
    "has_references",
    "quality_score",
    "duplication_score",
    "recommended_action",
    "replacement_skill",
    "deletion_reason",
    "config_cleanup_required",
    "risk_level",
]


@dataclass(frozen=True)
class AuditRow:
    skill_id: str
    category: str
    current_pack: str
    current_role: str
    lines: int
    has_scripts: bool
    has_references: bool
    quality_score: int
    duplication_score: int
    recommended_action: str
    replacement_skill: str
    deletion_reason: str
    config_cleanup_required: str
    risk_level: str


@dataclass(frozen=True)
class AuditArtifact:
    generated_at: str
    repo_root: str
    rows: list[AuditRow]

    def to_dict(self) -> dict[str, Any]:
        return {
            "generated_at": self.generated_at,
            "repo_root": self.repo_root,
            "summary": {
                "ml_skill_count": len(self.rows),
                "delete_candidate_count": sum(1 for row in self.rows if row.recommended_action == "delete"),
                "merge_candidate_count": sum(1 for row in self.rows if row.recommended_action == "merge-into"),
                "specialist_deferred_count": sum(
                    1 for row in self.rows if row.recommended_action == "defer-specialist-review"
                ),
            },
            "rows": [asdict(row) for row in self.rows],
        }


def _read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, tuple):
        return list(value)
    return [value]


def _flatten_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return " ".join([str(key) + " " + _flatten_text(item) for key, item in value.items()])
    if isinstance(value, list | tuple | set):
        return " ".join(_flatten_text(item) for item in value)
    return str(value)


def _contains_keyword(text: str, keyword: str) -> bool:
    text_lower = text.lower()
    keyword_lower = keyword.lower()
    if keyword_lower == "ml":
        return re.search(r"(?<![a-z0-9])ml(?![a-z0-9])", text_lower) is not None
    return keyword_lower in text_lower


def _is_ml_related(skill_id: str, pack_ids: set[str], metadata_text: str) -> bool:
    if "data-ml" in pack_ids:
        return True
    if skill_id in SPECIALIST_DEFER_SKILLS:
        return True
    haystack = f"{skill_id} {metadata_text}"
    return any(_contains_keyword(haystack, keyword) for keyword in ML_KEYWORDS)


def _has_files(directory: Path) -> bool:
    return directory.is_dir() and any(item.is_file() for item in directory.rglob("*"))


def _build_pack_index(pack_manifest: dict[str, Any]) -> dict[str, dict[str, set[str]]]:
    index: dict[str, dict[str, set[str]]] = {}
    for pack in _as_list(pack_manifest.get("packs")):
        if not isinstance(pack, dict):
            continue
        pack_id = str(pack.get("id", "")).strip()
        if not pack_id:
            continue
        defaults = {str(item).strip() for item in _flatten_text(pack.get("defaults_by_task")).split() if item}
        for value in _as_list(pack.get("skill_candidates")):
            skill_id = str(value).strip()
            if skill_id:
                record = index.setdefault(
                    skill_id,
                    {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()},
                )
                record["packs"].add(pack_id)
        for value in _as_list(pack.get("route_authority_candidates")):
            skill_id = str(value).strip()
            if skill_id:
                record = index.setdefault(
                    skill_id,
                    {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()},
                )
                record["packs"].add(pack_id)
                record["route_authority"].add(pack_id)
        for value in _as_list(pack.get("stage_assistant_candidates")):
            skill_id = str(value).strip()
            if skill_id:
                record = index.setdefault(
                    skill_id,
                    {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()},
                )
                record["packs"].add(pack_id)
                record["stage_assistant"].add(pack_id)
        defaults_by_task = pack.get("defaults_by_task")
        if isinstance(defaults_by_task, dict):
            for value in defaults_by_task.values():
                skill_id = str(value).strip()
                if skill_id:
                    record = index.setdefault(
                        skill_id,
                        {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()},
                    )
                    record["packs"].add(pack_id)
                    record["defaults"].add(pack_id)
        elif defaults:
            for skill_id in defaults:
                record = index.setdefault(
                    skill_id,
                    {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()},
                )
                record["packs"].add(pack_id)
                record["defaults"].add(pack_id)
    return index


def _current_role(record: dict[str, set[str]]) -> str:
    if record["route_authority"]:
        return "route_authority"
    if record["stage_assistant"]:
        return "stage_assistant"
    if record["defaults"]:
        return "default"
    return "candidate"


def _quality_score(
    skill_id: str,
    *,
    line_count: int,
    text_length: int,
    has_scripts: bool,
    has_references: bool,
) -> int:
    score = 1
    if line_count >= 20 or text_length >= 3500:
        score += 1
    if has_scripts:
        score += 1
    if has_references:
        score += 1
    if skill_id in OWNER_SKILLS:
        score += 1
    return min(score, 5)


def _duplication_score(
    skill_id: str,
    *,
    current_role: str,
    text: str,
    has_scripts: bool,
    has_references: bool,
) -> int:
    if skill_id in OWNER_SKILLS or skill_id in SPECIALIST_DEFER_SKILLS:
        return 1
    if skill_id in DEFAULT_REPLACEMENTS and not has_scripts and not has_references:
        return 5
    if current_role == "stage_assistant" and len(text) < 3500 and skill_id in DEFAULT_REPLACEMENTS:
        return 4
    if any(_contains_keyword(text, keyword) for keyword in ML_KEYWORDS):
        return 3
    return 1


def _risk_level(skill_id: str, recommended_action: str, replacement_skill: str) -> str:
    if recommended_action == "delete":
        return "low"
    if recommended_action == "defer-specialist-review":
        return "medium"
    if recommended_action == "merge-into" and not replacement_skill:
        return "high"
    if recommended_action == "merge-into":
        return "medium"
    return "low"


def _deletion_reason(
    recommended_action: str,
    *,
    skill_id: str,
    replacement_skill: str,
    quality_score: int,
    duplication_score: int,
) -> str:
    if recommended_action == "delete":
        return (
            f"通用模板型 ML skill；质量分 {quality_score}，重复分 {duplication_score}；"
            f"可由 {replacement_skill} 接管。"
        )
    if recommended_action == "merge-into":
        target = replacement_skill or "待定 owner"
        return f"存在重复或边界不清，先归入 {target} 复核，不直接删除。"
    if recommended_action == "defer-specialist-review":
        return "专业工具或框架绑定 skill，第一轮只暂缓专项评估，不删除。"
    if skill_id in OWNER_SKILLS:
        return "主专家或 owner skill，第一轮保留。"
    return "未满足第一轮删除条件。"


def _category(skill_id: str, recommended_action: str, current_role: str) -> str:
    if recommended_action == "delete":
        return "删除候选"
    if skill_id in SPECIALIST_DEFER_SKILLS:
        return "工具型"
    if skill_id in OWNER_SKILLS or current_role == "route_authority":
        return "主专家"
    if current_role == "stage_assistant":
        return "阶段助手"
    return "参考型"


def _config_cleanup_required(skill_id: str, pack_index: dict[str, dict[str, set[str]]], keyword_index: dict[str, Any], routing_rules: dict[str, Any]) -> str:
    cleanup: list[str] = []
    if skill_id in pack_index:
        cleanup.append("config/pack-manifest.json")
    if skill_id in (keyword_index.get("skills") or {}):
        cleanup.append("config/skill-keyword-index.json")
    if skill_id in (routing_rules.get("skills") or {}):
        cleanup.append("config/skill-routing-rules.json")
    cleanup.append("config/skills-lock.json")
    return "; ".join(dict.fromkeys(cleanup))


def _all_candidate_skill_ids(repo_root: Path, pack_index: dict[str, dict[str, set[str]]], keyword_index: dict[str, Any], routing_rules: dict[str, Any]) -> set[str]:
    skill_ids = set(pack_index)
    skill_ids.update((keyword_index.get("skills") or {}).keys())
    skill_ids.update((routing_rules.get("skills") or {}).keys())
    skills_root = repo_root / "bundled" / "skills"
    if skills_root.is_dir():
        skill_ids.update(path.name for path in skills_root.iterdir() if path.is_dir())
    return {str(skill_id).strip() for skill_id in skill_ids if str(skill_id).strip()}


def _metadata_text(skill_id: str, keyword_index: dict[str, Any], routing_rules: dict[str, Any], skill_text: str) -> str:
    keyword_payload = (keyword_index.get("skills") or {}).get(skill_id, {})
    route_payload = (routing_rules.get("skills") or {}).get(skill_id, {})
    return " ".join([skill_id, _flatten_text(keyword_payload), _flatten_text(route_payload), skill_text])


def _make_row(
    repo_root: Path,
    skill_id: str,
    pack_index: dict[str, dict[str, set[str]]],
    keyword_index: dict[str, Any],
    routing_rules: dict[str, Any],
) -> AuditRow | None:
    record = pack_index.get(skill_id, {"packs": set(), "route_authority": set(), "stage_assistant": set(), "defaults": set()})
    skill_dir = repo_root / "bundled" / "skills" / skill_id
    skill_md = skill_dir / "SKILL.md"
    skill_text = skill_md.read_text(encoding="utf-8-sig") if skill_md.exists() else ""
    metadata_text = _metadata_text(skill_id, keyword_index, routing_rules, skill_text)
    if not _is_ml_related(skill_id, record["packs"], metadata_text):
        return None

    line_count = len(skill_text.splitlines())
    has_scripts = _has_files(skill_dir / "scripts")
    has_references = _has_files(skill_dir / "references")
    current_role = _current_role(record)
    quality_score = _quality_score(
        skill_id,
        line_count=line_count,
        text_length=len(skill_text),
        has_scripts=has_scripts,
        has_references=has_references,
    )
    duplication_score = _duplication_score(
        skill_id,
        current_role=current_role,
        text=metadata_text,
        has_scripts=has_scripts,
        has_references=has_references,
    )
    replacement_skill = DEFAULT_REPLACEMENTS.get(skill_id, "")
    recommended_action = "keep"
    if skill_id in SPECIALIST_DEFER_SKILLS:
        recommended_action = "defer-specialist-review"
    elif skill_id in OWNER_SKILLS and quality_score >= 4:
        recommended_action = "keep"
    elif (
        quality_score <= 2
        and duplication_score >= 4
        and not has_scripts
        and not has_references
        and replacement_skill
    ):
        recommended_action = "delete"
    elif duplication_score >= 3 or quality_score <= 2:
        recommended_action = "merge-into"

    risk_level = _risk_level(skill_id, recommended_action, replacement_skill)
    if recommended_action == "delete" and risk_level == "high":
        recommended_action = "merge-into"
        risk_level = _risk_level(skill_id, recommended_action, replacement_skill)

    return AuditRow(
        skill_id=skill_id,
        category=_category(skill_id, recommended_action, current_role),
        current_pack=", ".join(sorted(record["packs"])),
        current_role=current_role,
        lines=line_count,
        has_scripts=has_scripts,
        has_references=has_references,
        quality_score=quality_score,
        duplication_score=duplication_score,
        recommended_action=recommended_action,
        replacement_skill=replacement_skill,
        deletion_reason=_deletion_reason(
            recommended_action,
            skill_id=skill_id,
            replacement_skill=replacement_skill,
            quality_score=quality_score,
            duplication_score=duplication_score,
        ),
        config_cleanup_required=_config_cleanup_required(skill_id, pack_index, keyword_index, routing_rules),
        risk_level=risk_level,
    )


def audit_repository(repo_root: Path) -> AuditArtifact:
    repo_root = repo_root.resolve()
    pack_manifest = _read_json(repo_root / "config" / "pack-manifest.json")
    keyword_index = _read_json(repo_root / "config" / "skill-keyword-index.json")
    routing_rules = _read_json(repo_root / "config" / "skill-routing-rules.json")
    pack_index = _build_pack_index(pack_manifest)
    rows = []
    for skill_id in sorted(_all_candidate_skill_ids(repo_root, pack_index, keyword_index, routing_rules)):
        row = _make_row(repo_root, skill_id, pack_index, keyword_index, routing_rules)
        if row is not None:
            rows.append(row)
    return AuditArtifact(
        generated_at=datetime.now(timezone.utc).isoformat(),
        repo_root=str(repo_root),
        rows=rows,
    )


def _markdown_table(rows: list[AuditRow], fields: list[str]) -> list[str]:
    lines = ["| " + " | ".join(fields) + " |", "| " + " | ".join(["---"] * len(fields)) + " |"]
    for row in rows:
        data = asdict(row)
        values = [str(data[field]).replace("\n", " ").replace("|", "\\|") for field in fields]
        lines.append("| " + " | ".join(values) + " |")
    return lines


def _write_markdown(path: Path, artifact: AuditArtifact) -> None:
    delete_rows = [row for row in artifact.rows if row.recommended_action == "delete"]
    merge_rows = [row for row in artifact.rows if row.recommended_action == "merge-into"]
    deferred_rows = [row for row in artifact.rows if row.recommended_action == "defer-specialist-review"]
    lines: list[str] = [
        "# ML Skills Pruning Audit",
        "",
        f"- Generated At: `{artifact.generated_at}`",
        f"- ML Skill Count: {len(artifact.rows)}",
        f"- Delete Candidates: {len(delete_rows)}",
        f"- Merge Candidates: {len(merge_rows)}",
        f"- Specialist Deferred: {len(deferred_rows)}",
        "",
        "## 删除候选",
        "",
    ]
    if delete_rows:
        lines.extend(
            _markdown_table(
                delete_rows,
                [
                    "skill_id",
                    "current_pack",
                    "current_role",
                    "quality_score",
                    "duplication_score",
                    "replacement_skill",
                    "risk_level",
                    "deletion_reason",
                ],
            )
        )
    else:
        lines.append("- none")
    lines.extend(["", "## 合并但暂不删除", ""])
    if merge_rows:
        lines.extend(_markdown_table(merge_rows, ["skill_id", "current_pack", "quality_score", "duplication_score", "replacement_skill", "deletion_reason"]))
    else:
        lines.append("- none")
    lines.extend(["", "## 专业工具型暂缓", ""])
    if deferred_rows:
        lines.extend(_markdown_table(deferred_rows, ["skill_id", "current_pack", "current_role", "risk_level", "deletion_reason"]))
    else:
        lines.append("- none")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_artifacts(repo_root: Path, artifact: AuditArtifact, output_dir: Path | None = None) -> dict[str, Path]:
    repo_root = repo_root.resolve()
    output_dir = output_dir or repo_root / "outputs" / "skills-audit"
    output_dir.mkdir(parents=True, exist_ok=True)

    json_path = output_dir / "ml-skills-pruning-audit.json"
    csv_path = output_dir / "ml-skills-pruning-candidates.csv"
    markdown_path = output_dir / "ml-skills-pruning-candidates.md"

    json_path.write_text(json.dumps(artifact.to_dict(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for row in artifact.rows:
            writer.writerow(asdict(row))
    _write_markdown(markdown_path, artifact)
    return {"json": json_path, "csv": csv_path, "markdown": markdown_path}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Audit ML-related bundled skills before pruning.")
    parser.add_argument("--repo-root", help="Optional repository root. Defaults to the current working directory.")
    parser.add_argument("--write-artifacts", action="store_true", help="Write JSON/CSV/Markdown artifacts.")
    parser.add_argument("--output-directory", help="Optional output directory for artifacts.")
    args = parser.parse_args(argv)

    repo_root = Path(args.repo_root).resolve() if args.repo_root else Path.cwd().resolve()
    artifact = audit_repository(repo_root)
    if args.write_artifacts:
        output_dir = Path(args.output_directory).resolve() if args.output_directory else None
        write_artifacts(repo_root, artifact, output_dir)
    print(json.dumps(artifact.to_dict(), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
