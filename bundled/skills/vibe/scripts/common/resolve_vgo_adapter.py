#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


def load_json(path: Path):
    with path.open("r", encoding="utf-8-sig") as fh:
        return json.load(fh)


def resolve_adapter(repo_root: Path, host_id: str):
    registry = load_json(repo_root / "adapters" / "index.json")
    normalized = (host_id or registry.get("default_adapter_id") or "codex").strip().lower()
    normalized = registry.get("aliases", {}).get(normalized, normalized)
    for entry in registry.get("adapters", []):
        if entry.get("id") == normalized:
            result = dict(entry)
            for key in ("host_profile", "settings_map", "closure", "manifest"):
                rel = entry.get(key)
                if rel:
                    result[f"{key}_path"] = str((repo_root / rel).resolve())
                    try:
                        result[f"{key}_json"] = load_json(repo_root / rel)
                    except FileNotFoundError:
                        result[f"{key}_json"] = None
            return result
    raise SystemExit(f"Unsupported VGO host id: {host_id}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--host", default="codex")
    parser.add_argument("--property")
    parser.add_argument("--format", choices=("json", "text"), default="text")
    args = parser.parse_args()

    adapter = resolve_adapter(Path(args.repo_root), args.host)
    if args.property:
        value = adapter
        for part in args.property.split("."):
            if isinstance(value, dict):
                value = value.get(part)
            else:
                value = None
            if value is None:
                break
        if args.format == "json":
            json.dump(value, sys.stdout, ensure_ascii=False, indent=2)
            sys.stdout.write("\n")
        elif isinstance(value, (dict, list)):
            json.dump(value, sys.stdout, ensure_ascii=False)
            sys.stdout.write("\n")
        elif value is not None:
            sys.stdout.write(f"{value}\n")
        return

    if args.format == "json":
        json.dump(adapter, sys.stdout, ensure_ascii=False, indent=2)
    else:
        sys.stdout.write(json.dumps(adapter, ensure_ascii=False))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
