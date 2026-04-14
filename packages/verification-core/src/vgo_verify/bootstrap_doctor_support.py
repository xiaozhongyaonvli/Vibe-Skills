from __future__ import annotations

import os
import re
import shutil
from pathlib import Path
from typing import Any

from ._io import load_json, utc_now, write_text
from ._repo import resolve_repo_root


END_MANAGED_BLOCK = "<!-- VIBESKILLS:END managed-block -->"
BEGIN_MANAGED_BLOCK = re.compile(
    r"^<!-- VIBESKILLS:BEGIN managed-block host=(?P<host>\S+) block=(?P<block>\S+) version=(?P<version>\d+) hash=(?P<hash>[a-f0-9]+) -->$",
    re.MULTILINE,
)
HOST_GLOBAL_INSTRUCTION_TARGETS = {
    "codex": {"relpath": "AGENTS.md", "documented_path": "~/.codex/AGENTS.md"},
    "claude-code": {"relpath": "CLAUDE.md", "documented_path": "~/.claude/CLAUDE.md"},
    "opencode": {"relpath": "AGENTS.md", "documented_path": "~/.config/opencode/AGENTS.md"},
}


def setting_value(settings: dict[str, Any] | None, name: str) -> str | None:
    if not isinstance(settings, dict):
        return None
    env = settings.get("env")
    if not isinstance(env, dict):
        return None
    value = env.get(name)
    if value is None:
        return None
    return str(value)


def placeholder_value(value: str | None) -> bool:
    if not value:
        return False
    trimmed = value.strip()
    return trimmed.startswith("<") and trimmed.endswith(">")


def setting_state(settings: dict[str, Any] | None, name: str) -> str:
    value = setting_value(settings, name)
    if value is None or not value.strip():
        return "missing"
    if placeholder_value(value):
        return "placeholder"
    return "configured"


def os_environ(name: str) -> str | None:
    value = os.environ.get(name)
    if value is None or not str(value).strip():
        return None
    return str(value)


def resolved_setting_state(settings: dict[str, Any] | None, name: str) -> tuple[str, str]:
    env_value = os_environ(name)
    if env_value:
        if placeholder_value(env_value):
            return "placeholder", "env"
        return "configured", "env"

    setting_value_text = setting_value(settings, name)
    if setting_value_text is None or not setting_value_text.strip():
        return "missing", "missing"
    if placeholder_value(setting_value_text):
        return "placeholder", "settings"
    return "configured", "settings"


def command_present(name: str) -> bool:
    return shutil.which(name) is not None


def inspect_global_instruction_bootstrap(
    target_root: Path,
    *,
    host_id: str | None,
) -> dict[str, Any]:
    receipt_path = target_root / ".vibeskills" / "global-instruction-bootstrap.json"
    receipt = None
    if receipt_path.exists():
        try:
            loaded = load_json(receipt_path)
        except Exception:
            loaded = None
        if isinstance(loaded, dict):
            receipt = loaded

    receipt_host = str(receipt.get("host") or "").strip() if isinstance(receipt, dict) else ""
    effective_host = receipt_host or str(host_id or "").strip()
    host_surface = HOST_GLOBAL_INSTRUCTION_TARGETS.get(effective_host or "")
    target_relpath = str(receipt.get("target_relpath") or "").strip() if isinstance(receipt, dict) else ""
    documented_path = str(receipt.get("documented_path") or "").strip() if isinstance(receipt, dict) else ""
    if host_surface:
        target_relpath = target_relpath or str(host_surface["relpath"])
        documented_path = documented_path or str(host_surface["documented_path"])
    target_path = (target_root / target_relpath).resolve(strict=False) if target_relpath else None
    applicable = bool(receipt_path.exists() or (target_path is not None and target_path.exists()))

    block_id = str(receipt.get("block_id") or "global-vibe-bootstrap").strip() if isinstance(receipt, dict) else "global-vibe-bootstrap"
    template_version = int(receipt.get("template_version") or 0) if isinstance(receipt, dict) else 0
    content_hash = str(receipt.get("content_hash") or "").strip() if isinstance(receipt, dict) else ""
    file_exists = bool(target_path and target_path.exists())
    duplicate_count = 0
    corruption = False

    if file_exists and target_path is not None:
        text = target_path.read_text(encoding="utf-8")
        begin_matches = list(BEGIN_MANAGED_BLOCK.finditer(text))
        end_count = text.count(END_MANAGED_BLOCK)
        if begin_matches or end_count:
            if len(begin_matches) != end_count:
                corruption = True
            else:
                duplicate_count = sum(1 for match in begin_matches if match.group("block") == block_id)

    healthy = applicable and bool(receipt) and file_exists and not corruption and duplicate_count == 1
    if not applicable:
        status = "not_applicable"
    elif healthy:
        status = "healthy"
    elif corruption:
        status = "corrupt"
    elif duplicate_count > 1:
        status = "duplicate"
    elif not file_exists:
        status = "missing_target"
    elif not receipt:
        status = "missing_receipt"
    else:
        status = "unhealthy"

    return {
        "applicable": applicable,
        "status": status,
        "healthy": healthy,
        "host_id": effective_host or None,
        "target_relpath": target_relpath or None,
        "documented_path": documented_path or None,
        "target_file": str(target_path) if target_path is not None else None,
        "exists": file_exists,
        "receipt_exists": receipt_path.exists(),
        "receipt_path": str(receipt_path.resolve(strict=False)),
        "receipt": receipt,
        "block_id": block_id,
        "template_version": template_version,
        "content_hash": content_hash or None,
        "duplicate_count": duplicate_count,
        "corruption": corruption,
    }
