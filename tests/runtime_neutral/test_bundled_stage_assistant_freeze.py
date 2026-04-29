from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
FREEZE_SCRIPT = REPO_ROOT / "scripts" / "runtime" / "Freeze-RuntimeInputPacket.ps1"


def resolve_powershell() -> str | None:
    candidates = [
        shutil.which("pwsh"),
        shutil.which("pwsh.exe"),
        r"C:\Program Files\PowerShell\7\pwsh.exe",
        r"C:\Program Files\PowerShell\7-preview\pwsh.exe",
        shutil.which("powershell"),
        shutil.which("powershell.exe"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return str(Path(candidate))
    return None


class BundledStageAssistantFreezeTests(unittest.TestCase):
    def test_runtime_freeze_keeps_vibe_runtime_authority_and_splits_stage_assistants_from_specialists(self) -> None:
        shell = resolve_powershell()
        if shell is None:
            self.skipTest("PowerShell executable not available in PATH")

        with tempfile.TemporaryDirectory() as tempdir:
            artifact_root = Path(tempdir) / "artifacts"
            run_id = "pytest-bundled-stage-assistant"
            command = [
                shell,
                "-NoLogo",
                "-NoProfile",
                "-File",
                str(FREEZE_SCRIPT),
                "-Task",
                "Create a journal-ready multi-panel figure with a colorblind-safe palette and vector export.",
                "-Mode",
                "interactive_governed",
                "-RunId",
                run_id,
                "-ArtifactRoot",
                str(artifact_root),
            ]
            subprocess.run(command, cwd=REPO_ROOT, capture_output=True, text=True, check=True)

            packet_path = next(artifact_root.rglob("runtime-input-packet.json"))
            packet = json.loads(packet_path.read_text(encoding="utf-8"))

            self.assertEqual("vibe", packet["divergence_shadow"]["runtime_selected_skill"])
            self.assertEqual("science-figures-visualization", packet["route_snapshot"]["selected_pack"])
            self.assertEqual("scientific-visualization", packet["route_snapshot"]["selected_skill"])
            legacy = packet["legacy_skill_routing"]

            recommendation_pairs = [
                (item["skill_id"], item["source"])
                for item in legacy["specialist_recommendations"]
            ]
            self.assertNotIn(("matplotlib", "route_stage_assistant"), recommendation_pairs)
            self.assertNotIn(("seaborn", "route_stage_assistant"), recommendation_pairs)
            self.assertNotIn(("plotly", "route_stage_assistant"), recommendation_pairs)

            hint_pairs = [
                (item["skill_id"], item["source"])
                for item in legacy["stage_assistant_hints"]
            ]
            self.assertNotIn(("matplotlib", "route_stage_assistant"), hint_pairs)
            self.assertNotIn(("seaborn", "route_stage_assistant"), hint_pairs)
            self.assertNotIn(("plotly", "route_stage_assistant"), hint_pairs)

            selected_ids = [
                item["skill_id"]
                for item in packet["skill_routing"]["selected"]
            ]
            self.assertEqual(["scientific-visualization"], selected_ids)


if __name__ == "__main__":
    unittest.main()
