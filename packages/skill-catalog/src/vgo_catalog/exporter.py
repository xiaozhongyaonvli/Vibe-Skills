from __future__ import annotations

from dataclasses import asdict
from pathlib import Path
import shutil

from vgo_contracts.catalog_descriptor import CatalogDescriptor


PACKAGE_ROOT = Path(__file__).resolve().parents[2]
CATALOG_ROOT = PACKAGE_ROOT / 'catalog'


def export_catalog_descriptor(output_root: Path | str) -> dict[str, object]:
    target_root = Path(output_root).resolve()
    exported_catalog_root = target_root / 'catalog'
    if exported_catalog_root.exists():
        shutil.rmtree(exported_catalog_root)
    shutil.copytree(CATALOG_ROOT, exported_catalog_root)

    descriptor = CatalogDescriptor(
        catalog_root=str(exported_catalog_root),
        profiles_manifest=str(exported_catalog_root / 'profiles' / 'index.json'),
        groups_manifest=str(exported_catalog_root / 'groups' / 'index.json'),
        metadata_manifest=str(exported_catalog_root / 'metadata' / 'index.json'),
        owner='skill-catalog',
        owners=['skill-catalog'],
    )
    return asdict(descriptor)
