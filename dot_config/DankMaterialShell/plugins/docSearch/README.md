# Document Search

A DankMaterialShell launcher plugin that searches the text *inside* PDF, DOCX,
PPTX and EPUB files and opens the original document.

Type `#` in the launcher, then a word. Nothing else in DMS can do this: the
built-in Files section matches filenames, and DMS never passes `-f body` to
dsearch, so a body match scores about 0.004 and never reaches the visible
results.

    #mitochondria
    #clostridioides
    #capitation

## How it works

`~/.local/bin/dank-doctext-sync` extracts document text into
`~/.cache/dank-doctext/*.doctext` sidecars. `.doctext` is in danksearch's
`text_extensions`, so those bodies are indexed. The plugin queries the dsearch
body field directly, then maps each sidecar back to the file it came from and
opens that.

Three stages run per settled query:

1. `GET http://127.0.0.1:43654/search?field=body&limit=N&q=...` (about 2 ms).
   If nothing is listening, the same query is retried through the `dsearch`
   binary, which reaches the same daemon over its unix socket (about 13 ms,
   nine tenths of it process startup). Both paths send identical flags, so the
   answer does not change shape depending on which transport won.
2. `awk -f doctext-resolve.awk` over every hit, reading line 1 of each sidecar
   (`# dank-doctext-source: /abs/path`) to recover the real filename and check
   that the original still opens. About 3 ms for twenty hits.
3. The same awk over the top few hits, pulling the sentence the match was found
   in for the subtitle. About 85 ms for five books, which is why it is separate:
   nothing waits on it.

Each stage publishes as soon as it has something, so the list fills in rather
than appearing all at once, and losing a later stage degrades the display
instead of breaking the search.

## Why the code is shaped the way it is

DMS calls `getItems(query)` synchronously and expects an array back, but the
search is out of process. So `getItems` never blocks and never starts a request
itself: it records the query, arms a debounce timer, and returns the cache. When
results arrive the plugin calls `pluginService.requestLauncherUpdate(pluginId)`,
which is the one signal DMS listens to. That makes DMS call `getItems` again,
which finds the cache warm and starts no new work. A request is only ever
started when the query has actually changed, which is what keeps that loop from
running away. `itemsChanged()` is emitted alongside for plugin API
compatibility; nothing in DMS 1.5.2 connects to it.

Every row carries `_preScored`. Without it the launcher's own relevance filter
drops every result, because the query word is in the file's contents and not in
its name.

Row ids are stable across all three publishes, so the selection stays where the
user put it when a later stage lands.

Failures are recorded as a timestamp, never as a permanent flag. A path is
retried after a minute, and every cooldown is cleared outright when the launcher
is reopened on the bare trigger. A daemon that gets restarted, or an `awk` that
reappears on `PATH`, recovers without reloading the plugin.

## Limitations, all inherent to the index

- Whole words only. `telom` finds nothing, `telomere` finds seven books. Fuzzy
  matching is retried automatically when an exact search comes up empty, which
  recovers typos but does not rescue partial words.
- No phrases and no boolean operators. `"cost containment"`, `cost AND
  containment` and `cost containment` are all the same OR query.
- No snippets from dsearch. It returns paths and scores and nothing else, so the
  snippet in the subtitle is read out of the sidecar by the plugin itself.
- Stopwords (`the`, `and`, `is`, `not`, `or`) are stripped from the index.

## Settings

Everything is in Settings > Plugins > Document Search. Notable ones:

- **Documents Only** is off by default. With it off, the plugin also matches
  every text file dsearch indexes: Markdown notes, lecture transcripts, source
  files. Those are content the launcher cannot find any other way. Turn it on to
  see only extracted PDFs, DOCX, PPTX and EPUBs.
- **Always Active** makes every launcher query also run a document search. That
  is a dsearch request on almost every keystroke, so it is off, and the plugin
  keeps DMS's own `launcherPluginVisibility` flag in step with it.
- **Index Status** reads `GET /stats` and tells you whether the daemon is up and
  how many files are indexed.

## Requirements

- dsearch (danksearch) running, listening on `127.0.0.1:43654`
- `dank-doctext-sync` run at least once, plus `dsearch index sync` afterwards
- `awk` on `PATH` for the filename mapping and snippets. Without it the plugin
  still returns every result, but names come from the flattened sidecar filename
  and there are no snippets.
- `~/.local/bin/dank-doctext-open` registered as the handler for `*.doctext`, so
  that opening a sidecar still lands on the original document

## Files

    plugin.json            manifest, trigger "#"
    DocSearch.qml          the launcher surface
    DocSearchSettings.qml  the settings panel
    doctext-resolve.awk    sidecar mapping and snippet extraction
