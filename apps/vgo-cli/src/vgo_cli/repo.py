from __future__ import annotations

import json
from pathlib import Path
import sys


CONTRACTS_SRC = Path(__file__).resolve().parents[4] / 'packages' / 'contracts' / 'src'
if str(CONTRACTS_SRC) not in sys.path:
    sys.path.insert(0, str(CONTRACTS_SRC))

from vgo_contracts.installed_runtime_contract import default_installed_runtime_config, merge_installed_runtime_config


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding='utf-8-sig'))


def load_governance(repo_root: Path) -> dict:
    return load_json(repo_root / 'config' / 'version-governance.json')


def get_installed_runtime_config(repo_root: Path) -> dict[str, object]:
    return merge_installed_runtime_config(load_governance(repo_root), default_installed_runtime_config())


def get_official_self_repo_metadata(repo_root: Path) -> dict[str, str]:
    governance = load_governance(repo_root)
    source = governance.get('source_of_truth') or {}
    official_repo = source.get('official_self_repo') or {}
    canonical_root = str(official_repo.get('canonical_root') or source.get('canonical_root') or '.').strip() or '.'
    return {
        'repo_url': str(official_repo.get('repo_url') or '').strip(),
        'default_branch': str(official_repo.get('default_branch') or '').strip(),
        'canonical_root': canonical_root,
    }


def resolve_canonical_repo_root(start_path: Path) -> Path | None:
    current = start_path.resolve()
    while True:
        if (current / '.git').exists() and (current / 'config' / 'version-governance.json').exists():
            return current
        if current.parent == current:
            return None
        current = current.parent
