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
# settings version: 3
set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "python3 not found; skipping." >&2; exit 0; }

# Registry plugins are git clones that `dms plugins update` rewrites, so they are
# not chezmoi-tracked. Reinstall by id instead. Safe to re-run; install on an
# already-present plugin is a no-op.
#
# docSearch is deliberately absent from this list. It is a local plugin with no
# registry entry, tracked directly under
# dot_config/DankMaterialShell/plugins/docSearch. This is a run_onchange_after_
# script, so chezmoi has already written its files by the time we get here. It
# still needs enabling below, same as the rest.
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
    # entries: a listed id gets priority 2.6 + index*0.01, lower sorting first.
    #
    # __files/__folders are deliberately NOT listed. Unlisted, they fall back to
    # DMS's built-in 4 and 4.1, which puts them below every plugin section. When
    # they were listed at index 0 and 1 they got 2.60/2.61 and outranked the
    # plugins, so searching ":e tear of" showed a Folders section above the
    # emoji the trigger was explicitly asking for. The file search is async and
    # lands after the trigger path has already returned, so file and folder
    # sections show up even in trigger mode; ordering is what keeps them out of
    # the way.
    "launcherPluginOrder": [
        "recentFiles", "calculator", "converter",
        "niriWindows", "emojiLauncher", "dankLauncherKeys",
        "webSearch", "docSearch",
    ],
    # docSearch runs a dsearch query per keystroke, so it must never be part of
    # the untriggered "all" search. The plugin also asserts this itself when it
    # loads; setting it here means a fresh provision has it right before the
    # shell has ever started.
    "launcherPluginVisibility": {
        "recentFiles": {"allowWithoutTrigger": False},
        "docSearch": {"allowWithoutTrigger": False},
    },
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
           "niriWindows", "webSearch", "dankLauncherKeys", "docSearch"]

# Triggers that must survive DMS rewriting the file. recentFiles ships "rf" in
# its manifest, which is alphabetic and therefore swallows every query starting
# with those two letters. docSearch already ships "#", but assert it anyway so
# an accidental change in the UI is corrected on the next apply.
TRIGGERS = {"recentFiles": ",", "docSearch": "#"}

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
for plugin, trigger in TRIGGERS.items():
    if ps[plugin].get("trigger") != trigger:
        ps[plugin]["trigger"] = trigger
        changed = True

if changed:
    pp.parent.mkdir(parents=True, exist_ok=True)
    tmp = pp.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(ps, indent=2))
    tmp.replace(pp)
    print("plugin_settings.json applied: {} plugins enabled, triggers {}".format(
        len(PLUGINS), ", ".join("{} {!r}".format(k, v) for k, v in TRIGGERS.items())))
PY
