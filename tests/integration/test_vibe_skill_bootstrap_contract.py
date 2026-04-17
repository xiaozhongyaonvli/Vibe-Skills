from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def test_vibe_skill_frontloads_canonical_bootstrap_contract() -> None:
    content = (REPO_ROOT / "SKILL.md").read_text(encoding="utf-8")

    assert "## Canonical Bootstrap" in content
    assert content.index("## Canonical Bootstrap") < content.index("## What `vibe` Does")
    assert "python3 -m vgo_cli.main canonical-entry" in content
    assert "python -m vgo_cli.main canonical-entry" in content
    assert '--artifact-root "<workspace_root>"' in content
    assert "Do not manually create `outputs/runtime/vibe-sessions/<run-id>/`" in content
    assert "Do not use the Vibe installation root as the governed artifact root" in content
    assert "Do not simulate `skeleton_check`" in content
    assert "Do not treat `scripts/runtime/Invoke-VibeCanonicalEntry.ps1` alone as proof-complete canonical entry" in content
    assert "Canonical launch claims require `host-launch-receipt.json`, `runtime-input-packet.json`, `governance-capsule.json`, and `stage-lineage.json`." in content
    assert "report `blocked` with the concrete failure reason" in content
    assert "Everything below this bootstrap section is reference material to follow only after successful canonical launch." in content
