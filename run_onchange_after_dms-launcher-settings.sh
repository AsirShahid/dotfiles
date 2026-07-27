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
# settings version: 2
set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "python3 not found; skipping." >&2; exit 0; }

# Registry plugins are git clones that `dms plugins update` rewrites, so they are
# not chezmoi-tracked. Reinstall by id instead. Safe to re-run; install on an
# already-present plugin is a no-op.
if command -v dms >/dev/null 2>&1; then
  for plugin in calculator converter emojiLauncher recentFiles \
                niriWindows webSearch dankLauncherKeys; do
    [ -d "${HOME}/.config/DankMaterialShell/plugins/${plugin}" ] && continue
    dms plugins install "${plugin}" >/dev/null 2>&1 \
      || echo "warn: dms plugins install ${plugin} failed" >&2
  done
fi

exec python3 - <<'PY'
import json, os, pathlib

p = pathlib.Path(os.path.expanduser("~/.config/DankMaterialShell/settings.json"))
want = {
    "dankLauncherV2IncludeFilesInAll": True,
    "dankLauncherV2IncludeFoldersInAll": True,
    "clipboardEnterToPaste": True,
    # detectTrigger uses a bare startsWith with no word boundary, so an
    # alphabetic trigger swallows every query starting with it ("cb" ate
    # "cbonsai"). Both alphabetic triggers moved to punctuation.
    "builtInPluginSettings": {
        "dms_settings_search":  {"enabled": True, "trigger": "?"},
        "dms_clipboard_search": {"enabled": True, "trigger": ";"},
    },
    # Shared ranking for plugin sections and the __files/__folders magic
    # entries: listed ids get priority 2.6 + index*0.01, unlisted get worse.
    "launcherPluginOrder": [
        "__files", "__folders",
        "recentFiles", "calculator", "converter",
        "niriWindows", "emojiLauncher", "dankLauncherKeys",
        "webSearch",
    ],
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

if not all(cfg.get(k) == v for k, v in want.items()):
    cfg.update(want)
    tmp = p.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cfg, indent=2))
    tmp.replace(p)
    print("DMS launcher settings applied:", ", ".join(want))

# Plugin enablement and recentFiles' trigger live in plugin_settings.json, a
# separate file. Doing it declaratively here rather than via
# `dms ipc call plugins enable` means it also works on a fresh provision where
# no shell is running yet. DMS rewrites this file whenever a plugin is enabled,
# which resets the trigger to the plugin.json default, so re-assert that too.
PLUGINS = ["calculator", "converter", "emojiLauncher", "recentFiles",
           "niriWindows", "webSearch", "dankLauncherKeys"]

pp = pathlib.Path(os.path.expanduser("~/.config/DankMaterialShell/plugin_settings.json"))
if pp.exists():
    try:
        ps = json.loads(pp.read_text())
    except json.JSONDecodeError:
        raise SystemExit("plugin_settings.json is not valid JSON; leaving it alone.")
else:
    ps = {}

changed = False
for plugin in PLUGINS:
    if ps.setdefault(plugin, {}).get("enabled") is not True:
        ps[plugin]["enabled"] = True
        changed = True
if ps["recentFiles"].get("trigger") != ",":
    ps["recentFiles"]["trigger"] = ","
    changed = True

if changed:
    pp.parent.mkdir(parents=True, exist_ok=True)
    tmp = pp.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(ps, indent=2))
    tmp.replace(pp)
    print("plugin_settings.json applied: 7 plugins enabled, recentFiles trigger ','")
PY
