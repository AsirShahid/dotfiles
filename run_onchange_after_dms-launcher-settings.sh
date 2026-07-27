#!/usr/bin/env bash
# Applies the DMS launcher settings that make Mod+Space behave like GNOME's
# overview search: file and folder hits merged into the main result list
# instead of hiding behind the "/" prefix.
#
# settings.json is NOT chezmoi-managed on purpose. DMS rewrites the whole
# 21 KB file on every settings change, so tracking it would leave the source
# permanently dirty. This script merges only the keys we care about and leaves
# everything else alone.
#
# Idempotent: re-running is a no-op. DMS watches settings.json (watchChanges,
# ~50 ms reload), so no restart is needed when the shell is running.
#
# settings version: 1
set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "python3 not found; skipping." >&2; exit 0; }

exec python3 - <<'PY'
import json, os, pathlib

p = pathlib.Path(os.path.expanduser("~/.config/DankMaterialShell/settings.json"))
want = {
    "dankLauncherV2IncludeFilesInAll": True,
    "dankLauncherV2IncludeFoldersInAll": True,
}

if p.exists():
    try:
        cfg = json.loads(p.read_text())
    except json.JSONDecodeError:
        # Never clobber a file DMS may be mid-write on.
        raise SystemExit("settings.json is not valid JSON; leaving it alone.")
else:
    # Fresh provision, before DMS has ever run. DMS merges its defaults on top.
    p.parent.mkdir(parents=True, exist_ok=True)
    cfg = {}

if all(cfg.get(k) == v for k, v in want.items()):
    raise SystemExit(0)

cfg.update(want)
tmp = p.with_suffix(".json.tmp")
tmp.write_text(json.dumps(cfg, indent=2))
tmp.replace(p)
print("DMS launcher settings applied:", ", ".join(want))
PY
