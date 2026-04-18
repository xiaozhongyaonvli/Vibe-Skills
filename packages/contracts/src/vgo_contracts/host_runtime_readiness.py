from __future__ import annotations

import json
import os
import shutil
from pathlib import Path
from typing import Any

from .adapter_registry_support import load_adapter_registry
from .canonical_vibe_contract import resolve_canonical_vibe_contract

REPO_ROOT = Path(__file__).resolve().parents[4]


def _resolve_repo_root(repo_root: str | Path | None) -> Path:
    """Resolve the repo root used for registry and policy lookups."""
    if repo_root is None:
        return REPO_ROOT
    return Path(repo_root).resolve()


def _load_native_specialist_execution_policy(repo_root: str | Path | None) -> dict[str, Any]:
    """Load native specialist execution policy data from the active repo tree."""
    repo_candidates = [_resolve_repo_root(repo_root)]
    if REPO_ROOT not in repo_candidates:
        repo_candidates.append(REPO_ROOT)
    for candidate_root in repo_candidates:
        policy_path = candidate_root / "config" / "native-specialist-execution-policy.json"
        if policy_path.exists():
            return json.loads(policy_path.read_text(encoding="utf-8-sig"))
    raise RuntimeError("native-specialist-execution-policy.json not found")


def _resolve_direct_runtime_policy(repo_root: str | Path | None, host_id: str) -> dict[str, Any] | None:
    """Return the native direct-runtime policy entry for a given host."""
    policy = _load_native_specialist_execution_policy(repo_root)
    for adapter in policy.get("adapters") or []:
        if isinstance(adapter, dict) and str(adapter.get("id") or "").strip().lower() == host_id:
            return dict(adapter)
    return None


def _resolve_executable_candidate(raw: str) -> str | None:
    """Resolve a command or file path to an executable file path."""
    candidate = str(raw or "").strip()
    if not candidate:
        return None
    resolved = shutil.which(candidate)
    if resolved:
        return str(Path(resolved).resolve())
    path_candidate = Path(candidate).expanduser()
    if path_candidate.is_file():
        return str(path_candidate.resolve())
    return None


def _fallback_canonical_vibe_contract(host_id: str | None) -> dict[str, Any]:
    """Return a safe bridged contract when canonical contract lookup fails."""
    normalized_host_id = str(host_id or "").strip().lower()
    return {
        "host_id": normalized_host_id,
        "entry_mode": "bridged_runtime",
        "fallback_policy": "blocked",
        "proof_required": True,
        "allow_skill_doc_fallback": False,
        "launcher_kind": "managed_bridge",
        "supports_bounded_stop": True,
    }


def evaluate_host_runtime_readiness(
    repo_root: str | Path | None,
    host_id: str | None,
    *,
    specialist_wrapper_ready: bool | None = None,
) -> dict[str, Any]:
    """Evaluate whether a host is truly ready for canonical vibe execution."""
    resolved_repo_root = _resolve_repo_root(repo_root)
    try:
        load_adapter_registry(resolved_repo_root)
        contract_repo_root: str | Path | None = resolved_repo_root
    except RuntimeError:
        contract_repo_root = REPO_ROOT
    try:
        contract = resolve_canonical_vibe_contract(contract_repo_root, host_id)
    except ValueError:
        contract = _fallback_canonical_vibe_contract(host_id)
    normalized_host_id = str(contract.get("host_id") or "").strip().lower()
    readiness_driver = "direct_runtime" if contract["entry_mode"] == "direct_runtime" else "specialist_wrapper"
    wrapper_ready = bool(specialist_wrapper_ready)
    direct_runtime: dict[str, Any] = {
        "required": readiness_driver == "direct_runtime",
        "ready": False,
        "invocation_kind": None,
        "executable_env": None,
        "command": None,
        "resolved_path": None,
        "source": None,
        "reason": "not_applicable",
    }

    if readiness_driver == "direct_runtime":
        try:
            policy_adapter = _resolve_direct_runtime_policy(contract_repo_root, normalized_host_id)
        except RuntimeError:
            policy_adapter = None
        if policy_adapter is None:
            direct_runtime["reason"] = "native_specialist_policy_missing"
        else:
            invocation_kind = str(policy_adapter.get("invocation_kind") or "").strip()
            env_name = str(policy_adapter.get("executable_env") or "").strip()
            configured_command = str(policy_adapter.get("command") or "").strip()
            env_value = str(os.environ.get(env_name) or "").strip() if env_name else ""
            resolved_path = None
            source = None
            command = configured_command

            if env_value:
                resolved_path = _resolve_executable_candidate(env_value)
                command = env_value
                if resolved_path:
                    source = f"env:{env_name}"
            if resolved_path is None and configured_command:
                resolved_path = _resolve_executable_candidate(configured_command)
                if resolved_path:
                    source = f"path:{configured_command}"

            direct_runtime.update(
                {
                    "invocation_kind": invocation_kind or None,
                    "executable_env": env_name or None,
                    "command": command or None,
                    "resolved_path": resolved_path,
                    "source": source,
                    "ready": resolved_path is not None,
                    "reason": (
                        "native_specialist_execution_ready"
                        if resolved_path is not None and invocation_kind == "direct"
                        else f"native_specialist_adapter_command_unavailable:{configured_command or normalized_host_id}"
                    ),
                }
            )

    effective_runtime_ready = direct_runtime["ready"] if readiness_driver == "direct_runtime" else wrapper_ready
    return {
        "host_id": normalized_host_id,
        "entry_mode": str(contract["entry_mode"]),
        "launcher_kind": str(contract["launcher_kind"]),
        "readiness_driver": readiness_driver,
        "specialist_wrapper_required": readiness_driver != "direct_runtime",
        "specialist_wrapper_ready": wrapper_ready,
        "effective_runtime_ready": bool(effective_runtime_ready),
        "recommended_host_closure_state": "closed_ready" if effective_runtime_ready else "configured_offline_unready",
        "direct_runtime": direct_runtime,
    }
