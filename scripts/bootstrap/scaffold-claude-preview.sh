#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=""
TARGET_ROOT=""
FORCE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --target-root) TARGET_ROOT="$2"; shift 2 ;;
    --force) FORCE="true"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${REPO_ROOT}" || -z "${TARGET_ROOT}" ]]; then
  echo "[FAIL] --repo-root and --target-root are required" >&2
  exit 1
fi

mkdir -p "${TARGET_ROOT}/hooks"
if [[ "${FORCE}" == "true" || ! -f "${TARGET_ROOT}/settings.json" ]]; then
  cp "${REPO_ROOT}/config/settings.template.claude.json" "${TARGET_ROOT}/settings.json"
fi
if [[ -d "${REPO_ROOT}/hooks" ]]; then
  cp -R "${REPO_ROOT}/hooks/." "${TARGET_ROOT}/hooks/"
fi

python3 - <<'PY' "${TARGET_ROOT}"
import json, sys
from pathlib import Path

target = Path(sys.argv[1]).resolve()
print(json.dumps({
    "result": "PASS",
    "host_id": "claude-code",
    "target_root": str(target),
    "settings_path": str((target / "settings.json").resolve()),
    "hooks_root": str((target / "hooks").resolve()),
}, ensure_ascii=False, indent=2))
PY
