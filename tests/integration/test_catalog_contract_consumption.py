from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACTS_SRC = ROOT / 'packages' / 'contracts' / 'src'
INSTALLER_SRC = ROOT / 'packages' / 'installer-core' / 'src'
CATALOG_SRC = ROOT / 'packages' / 'skill-catalog' / 'src'
for src in (CONTRACTS_SRC, INSTALLER_SRC, CATALOG_SRC):
    if str(src) not in sys.path:
        sys.path.insert(0, str(src))

from vgo_catalog.exporter import export_catalog_descriptor
from vgo_installer.install_plan import build_install_plan


def test_catalog_exports_descriptor_without_runtime_imports(tmp_path) -> None:
    descriptor = export_catalog_descriptor(tmp_path)
    assert 'runtime' not in descriptor['owner']
    assert descriptor['owner'] == 'skill-catalog'
    assert descriptor['profiles_manifest'].endswith('catalog/profiles/index.json')
    assert descriptor['groups_manifest'].endswith('catalog/groups/index.json')


def test_installer_plan_can_consume_catalog_descriptor_without_topology_traversal(tmp_path) -> None:
    descriptor = export_catalog_descriptor(tmp_path)
    plan = build_install_plan(
        profile='minimal',
        host_id='codex',
        target_root=tmp_path,
        managed_skill_names=['vibe', 'brainstorming'],
        packaging_manifest={
            'package_id': 'runtime-core-minimal',
            'catalog_owner': descriptor['owner'],
            'catalog_root': descriptor['catalog_root'],
            'profiles_manifest': descriptor['profiles_manifest'],
            'groups_manifest': descriptor['groups_manifest'],
        },
    )

    assert plan.packaging_manifest['catalog_owner'] == 'skill-catalog'
    assert 'bundled/skills' not in str(plan.packaging_manifest['catalog_root'])
