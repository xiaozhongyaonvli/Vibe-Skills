from __future__ import annotations

from pathlib import Path
from typing import Callable, Any

from ._io import load_json, write_json_file
from .global_instruction_contract import GlobalInstructionSurface, resolve_global_instruction_surface
from .global_instruction_merge import (
    ManagedBlockMutationError,
    merge_managed_block_text,
    parse_managed_blocks,
    remove_managed_block_text,
)


TrackCreatedPath = Callable[[Path | str], None]
RecordMergedFile = Callable[..., None]


def _write_text_file(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _receipt_path(target_root: Path) -> Path:
    return target_root / ".vibeskills" / "global-instruction-bootstrap.json"


def _build_receipt(
    *,
    surface: GlobalInstructionSurface,
    target_path: Path,
    mutation: Any,
    status: str = "ok",
    error_code: str | None = None,
) -> dict[str, object]:
    return {
        "schema_version": 1,
        "status": status,
        "host": mutation.host_id if getattr(mutation, "host_id", "") else None,
        "target_file": str(target_path.resolve(strict=False)),
        "target_relpath": surface.relpath,
        "documented_path": surface.documented_path,
        "block_id": surface.managed_block_id,
        "action": getattr(mutation, "action", None),
        "template_version": surface.template_version,
        "content_hash": getattr(mutation, "content_hash", None),
        "error_code": error_code,
    }


def materialize_global_instruction_bootstrap(
    repo_root: Path,
    target_root: Path,
    adapter: dict[str, object],
    *,
    track_created_path: TrackCreatedPath,
    record_merged_file: RecordMergedFile,
) -> dict[str, object] | None:
    surface = resolve_global_instruction_surface(adapter)
    if surface is None:
        return None

    target_path = surface.target_path(target_root)
    template_path = surface.template_path(repo_root)
    created_if_absent = not target_path.exists()
    existing_text = target_path.read_text(encoding="utf-8") if target_path.exists() else None
    body = template_path.read_text(encoding="utf-8")
    mutation = merge_managed_block_text(
        existing_text,
        body=body,
        host_id=str(adapter.get("id") or adapter.get("adapter_id") or ""),
        block_id=surface.managed_block_id,
        version=surface.template_version,
    )
    if mutation.action != "unchanged":
        _write_text_file(target_path, mutation.text)
    if created_if_absent and target_path.exists():
        track_created_path(target_path)
    record_merged_file(target_path, created_if_absent=created_if_absent, managed_block_id=surface.managed_block_id)

    receipt_path = _receipt_path(target_root)
    receipt = _build_receipt(surface=surface, target_path=target_path, mutation=mutation)
    write_json_file(receipt_path, receipt)
    track_created_path(receipt_path)
    return {
        **receipt,
        "receipt_path": str(receipt_path.resolve(strict=False)),
    }


def inspect_global_instruction_bootstrap(target_root: Path, adapter: dict[str, object]) -> dict[str, object] | None:
    surface = resolve_global_instruction_surface(adapter)
    if surface is None:
        return None
    target_path = surface.target_path(target_root)
    receipt_path = _receipt_path(target_root)
    receipt = load_json(receipt_path) if receipt_path.exists() else None
    text = target_path.read_text(encoding="utf-8") if target_path.exists() else ""
    try:
        blocks = parse_managed_blocks(text) if target_path.exists() else []
        matching = [block for block in blocks if block.block_id == surface.managed_block_id]
        duplicate_count = len(matching)
        corruption = False
    except ManagedBlockMutationError as exc:
        matching = []
        duplicate_count = 0
        corruption = exc.code == "error_corrupt_managed_block"
    return {
        "target_file": str(target_path.resolve(strict=False)),
        "target_relpath": surface.relpath,
        "documented_path": surface.documented_path,
        "exists": target_path.exists(),
        "block_id": surface.managed_block_id,
        "duplicate_count": duplicate_count,
        "corruption": corruption,
        "healthy": target_path.exists() and duplicate_count == 1 and not corruption,
        "template_version": surface.template_version,
        "receipt_path": str(receipt_path.resolve(strict=False)),
        "receipt_exists": receipt_path.exists(),
        "receipt": receipt if isinstance(receipt, dict) else None,
    }


def remove_global_instruction_bootstrap(
    target_root: Path,
    adapter: dict[str, object],
    *,
    preview: bool,
) -> dict[str, object] | None:
    surface = resolve_global_instruction_surface(adapter)
    if surface is None:
        return None
    target_path = surface.target_path(target_root)
    receipt_path = _receipt_path(target_root)
    if not target_path.exists():
        if not preview and receipt_path.exists():
            receipt_path.unlink()
        return None
    existing_text = target_path.read_text(encoding="utf-8")
    mutation = remove_managed_block_text(existing_text, block_id=surface.managed_block_id)
    removed_file = False
    if not preview:
        if mutation.action == "removed" and not mutation.text.strip():
            target_path.unlink()
            removed_file = True
        elif mutation.action == "removed":
            _write_text_file(target_path, mutation.text)
        if receipt_path.exists():
            receipt_path.unlink()
    return {
        "action": mutation.action,
        "target_file": str(target_path.resolve(strict=False)),
        "block_id": surface.managed_block_id,
        "removed_file": removed_file,
        "receipt_path": str(receipt_path.resolve(strict=False)),
    }
