from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import unittest
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
RUNTIME_SRC = REPO_ROOT / "packages" / "runtime-core" / "src"
if str(RUNTIME_SRC) not in sys.path:
    sys.path.insert(0, str(RUNTIME_SRC))

from vgo_runtime.router_contract_runtime import route_prompt  # noqa: E402


LEGACY_PACK_ROW_FIELDS = {"stage_assistant_candidates", "route_authority_eligible"}
LEGACY_CANDIDATE_ROW_FIELDS = {"legacy_role", "route_authority_eligible"}


ROUTE_CASES = [
    (
        "帮我做科研绘图，产出期刊级 figure，多面板、颜色无障碍、矢量导出",
        "L",
        "research",
        "science-figures-visualization",
        "scientific-visualization",
    ),
    (
        "请用 LaTeX 构建论文 PDF，检查 bibtex 引用、模板和 submission checklist",
        "L",
        "coding",
        "scholarly-publishing-workflow",
        "latex-submission-pipeline",
    ),
    (
        "机器学习 data preprocessing pipeline：清洗数据、feature encoding、standardize data、validate input data",
        "L",
        "coding",
        "data-ml",
        "preprocessing-data-with-automated-pipelines",
    ),
    (
        "request code review before merge：请整理提交评审材料，准备 code review request",
        "L",
        "review",
        "code-quality",
        "requesting-code-review",
    ),
]


def resolve_powershell() -> str | None:
    candidates = [
        shutil.which("pwsh"),
        shutil.which("pwsh.exe"),
        r"C:\Program Files\PowerShell\7\pwsh.exe",
        shutil.which("powershell"),
        shutil.which("powershell.exe"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return str(Path(candidate))
    return None


def assert_public_route_output_shape(testcase: unittest.TestCase, result: dict[str, Any]) -> None:
    testcase.assertIn("ranked", result)
    testcase.assertIsInstance(result["ranked"], list)
    for pack_row in result["ranked"]:
        testcase.assertIsInstance(pack_row, dict)
        for field in LEGACY_PACK_ROW_FIELDS:
            testcase.assertNotIn(field, pack_row, pack_row.get("pack_id"))
        custom_admission = pack_row.get("custom_admission")
        if isinstance(custom_admission, dict):
            testcase.assertNotIn("route_authority_eligible", custom_admission, pack_row.get("pack_id"))
        ranking = pack_row.get("candidate_ranking") or []
        testcase.assertIsInstance(ranking, list)
        for candidate_row in ranking:
            testcase.assertIsInstance(candidate_row, dict)
            for field in LEGACY_CANDIDATE_ROW_FIELDS:
                testcase.assertNotIn(field, candidate_row, candidate_row.get("skill"))


class RuntimeRouteOutputShapeTests(unittest.TestCase):
    def test_python_route_output_has_no_legacy_role_fields(self) -> None:
        for prompt, grade, task_type, expected_pack, expected_skill in ROUTE_CASES:
            with self.subTest(expected_pack=expected_pack, expected_skill=expected_skill):
                result = route_prompt(prompt=prompt, grade=grade, task_type=task_type, repo_root=REPO_ROOT)

                self.assertEqual(expected_pack, result["selected"]["pack_id"])
                self.assertEqual(expected_skill, result["selected"]["skill"])
                assert_public_route_output_shape(self, result)

    def test_powershell_route_output_has_no_legacy_role_fields(self) -> None:
        shell = resolve_powershell()
        if shell is None:
            self.skipTest("PowerShell executable not available")

        script_path = REPO_ROOT / "scripts" / "router" / "resolve-pack-route.ps1"
        for prompt, grade, task_type, expected_pack, expected_skill in ROUTE_CASES:
            with self.subTest(expected_pack=expected_pack, expected_skill=expected_skill):
                completed = subprocess.run(
                    [
                        shell,
                        "-NoLogo",
                        "-NoProfile",
                        "-File",
                        str(script_path),
                        "-Prompt",
                        prompt,
                        "-Grade",
                        grade,
                        "-TaskType",
                        task_type,
                    ],
                    cwd=REPO_ROOT,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    check=True,
                    env={**os.environ, "VGO_DISABLE_NATIVE_SPECIALIST_EXECUTION": "1"},
                )
                result = json.loads(completed.stdout)

                self.assertEqual(expected_pack, result["selected"]["pack_id"])
                self.assertEqual(expected_skill, result["selected"]["skill"])
                assert_public_route_output_shape(self, result)


if __name__ == "__main__":
    unittest.main()
