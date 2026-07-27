// Document Search: full text search inside PDF, DOCX, PPTX and EPUB files.
//
// The launcher calls getItems(query) synchronously and expects an array back,
// but the search runs out of process. So getItems never blocks and never
// starts a request itself. It records the query, starts a debounce timer, and
// returns whatever is already cached. When results arrive, the callback updates
// the cache and calls pluginService.requestLauncherUpdate(pluginId), which is
// the one signal DMS listens to (Modals/DankLauncherV2/Controller.qml has a
// Connections block on PluginService for it). That makes DMS call getItems
// again with the same query, which now finds the cache warm and starts no new
// work. itemsChanged() is emitted alongside for plugin API compatibility;
// nothing in DMS 1.5.2 connects to it.
//
// Three stages run per settled query:
//
//   1. GET http://127.0.0.1:43654/search?field=body&limit=N&q=...
//      Body search only. In the launcher's default multi field mode a body
//      match scores around 0.004 and never reaches the visible results, which
//      is the whole reason this plugin exists. Measured at 2 ms against the
//      daemon, versus 13 ms for the dsearch binary, which spends nine tenths
//      of its time on process startup and then asks the same daemon. The
//      binary stays as a fallback for when the TCP listener is off; it reaches
//      the daemon over its unix socket. Both paths send identical flags.
//      Results are absolute paths, which for extracted documents are .doctext
//      sidecars under ~/.cache/dank-doctext rather than the original files.
//
//   2. awk -f doctext-resolve.awk "" 0 <every hit path>
//      Reads line 1 of each hit ("# dank-doctext-source: /abs/path") and checks
//      that the original still opens. Measured at 3 ms for twenty hits, so the
//      real filenames land almost immediately after the results appear.
//
//   3. awk -f doctext-resolve.awk <needle> <budget> <top hit paths>
//      Pulls a body snippet for the leading few hits. Around 85 ms for five
//      books, which is why it is a separate stage: nothing waits on it.
//
// Every stage publishes as soon as it has something, so the list fills in
// rather than appearing all at once, and losing any later stage degrades the
// display instead of breaking the search. Every failure is latched with a
// timestamp rather than a boolean, so a transient outage costs one cooldown
// and not the rest of the session.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

QtObject {
    id: root

    // Injected by PluginService.loadPlugin when the launcher surface is
    // created. It is the only property DMS sets on a launcher instance.
    property var pluginService: null
    readonly property string pluginId: "docSearch"

    signal itemsChanged

    // ---------------------------------------------------------------- settings

    property string trigger: "#"
    property bool noTrigger: false
    property int resultLimit: 20
    property int minQueryLength: 3
    property bool showSnippets: true
    property int snippetBudget: 5
    property bool fuzzyFallback: true
    property bool documentsOnly: false
    property bool cliFallback: true

    // ------------------------------------------------------------- environment

    readonly property string homeDir: Quickshell.env("HOME") || ""

    // Loopback only, no authentication, which is the daemon's whole security
    // model. Matches listen_addr in ~/.config/danksearch/config.toml.
    readonly property string apiBase: "http://127.0.0.1:43654"

    // Absolute path of the awk program shipped next to this file. DMS appends a
    // cache busting query string to the component URL on `plugin-scan reload`,
    // so anything after '?' is dropped before the path reaches a process.
    readonly property string resolveScript: {
        var url = Qt.resolvedUrl("doctext-resolve.awk").toString();
        var q = url.indexOf("?");
        if (q !== -1)
            url = url.substring(0, q);
        if (url.indexOf("file://") === 0)
            url = url.substring(7);
        try {
            return decodeURIComponent(url);
        } catch (e) {
            return url;
        }
    }

    // ------------------------------------------------------- failure cooldowns
    //
    // Each of these holds the epoch millisecond of the last failure, or 0 when
    // the path is healthy. A path is retried once the cooldown has elapsed, and
    // every one of them is cleared outright when the launcher is reopened on
    // the bare trigger. Nothing here is ever latched for the life of the shell:
    // a daemon that is restarted, an awk that reappears on PATH, or a plugin
    // directory that is remounted all recover on their own.

    readonly property int retryCooldownMs: 60000
    property double httpFailedAt: 0
    property double dsearchFailedAt: 0
    property double resolveFailedAt: 0

    function _usable(stamp) {
        return stamp === 0 || (Date.now() - stamp) > retryCooldownMs;
    }

    function _resetFailureLatches() {
        httpFailedAt = 0;
        dsearchFailedAt = 0;
        resolveFailedAt = 0;
    }

    // ---------------------------------------------------------- index liveness
    //
    // GET /stats is the only honest answer to "can this plugin work right now".
    // It proves the daemon is up, tells us how many files are indexed, and does
    // it without touching the search path. Probed at load and on each launcher
    // activation, throttled, never per keystroke.

    property int indexedFiles: -1
    property bool statsOk: false
    property double statsProbedAt: 0

    function _probeStats() {
        var now = Date.now();
        if (statsProbedAt !== 0 && (now - statsProbedAt) < 30000)
            return;
        statsProbedAt = now;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root.statsOk = false;
                return;
            }
            try {
                var s = JSON.parse(xhr.responseText);
                root.statsOk = true;
                if (typeof s.total_files === "number")
                    root.indexedFiles = s.total_files;
            } catch (e) {
                root.statsOk = false;
            }
        };
        try {
            xhr.open("GET", apiBase + "/stats");
            xhr.send();
        } catch (e) {
            statsOk = false;
        }
    }

    // ------------------------------------------------------------- query state

    // Bumped whenever the query changes and whenever work is cancelled. Every
    // callback compares the generation captured at launch against this and
    // drops itself if they differ. Ignoring stale output is what makes races
    // impossible: a request that has already been sent cannot be un-sent, but
    // its answer can always be discarded.
    property int _gen: 0

    property string _activeQuery: ""   // query currently being worked on
    property string _servedQuery: ""   // query that _results describes
    property var _results: []
    property bool _fuzzyTried: false
    property bool _cliTried: false

    // "" when there is no error. Otherwise one of the classified kinds below,
    // which map to a specific row so the user is told what to actually do.
    property string _errorKind: ""
    property string _errorDetail: ""

    // The single in-flight HTTP request, or null. Holding the object is what
    // lets a superseded response be recognised and dropped.
    property var _httpJob: null

    // ------------------------------------------------------------- job control

    // One Process object serves the CLI fallback and both awk stages. Within a
    // generation the stages run strictly one after the other, and a new
    // generation cancels whatever is in flight, so two objects would never both
    // be busy. Reusing a single statically declared object means nothing is
    // created or destroyed at runtime, which is the simplest guarantee that no
    // process object leaks.
    readonly property int jobNone: 0
    readonly property int jobSearch: 1
    readonly property int jobMap: 2
    readonly property int jobSnippet: 3

    property int _jobKind: 0
    property int _jobGen: -1
    property bool _jobFuzzy: false
    property var _pending: null        // {kind, cmd, gen, fuzzy} waiting for the slot
    property int _launchRetries: 0

    // True from the moment a child is asked to stop until the next launch. It
    // tells the start check that running === false is expected rather than a
    // failed exec.
    property bool _stopRequested: false

    // All three have to arrive before the output can be trusted, and they come
    // in any order. Waiting on stdout and exit alone is not enough: a run that
    // fails prints nothing on stdout and everything useful on stderr, and if
    // exited arrives first the error message would be read while still empty.
    property bool _outDone: false
    property bool _errDone: false
    property bool _exitDone: false
    property int _exitCode: -1

    // ============================================================ DMS entry point

    function getItems(query) {
        var q = (query || "").trim();

        // Empty query. DMS lands here as soon as the bare trigger is typed, so
        // this is the launcher activation hook: clear every failure cooldown
        // and re-probe the daemon, because whatever was broken last time may
        // well have been fixed since. Never start a search and never publish
        // from this path.
        if (q.length === 0) {
            _resetFailureLatches();
            _probeStats();
            _cancel();
            return [_statusRow("idle", "Search inside documents", "Type at least " + minQueryLength + " characters. The index matches whole words.", "material:find_in_page")];
        }

        if (q.length < minQueryLength) {
            _cancel();
            return [_statusRow("short", "Keep typing", "Body search matches whole words, so a partial word finds nothing", "material:keyboard")];
        }

        // The only place a search is ever started. Gating on a query change is
        // what stops the publish loop: requestLauncherUpdate makes DMS call
        // getItems again with the same query, and that call falls straight
        // through to the cache below instead of starting another request.
        if (q !== _activeQuery) {
            _activeQuery = q;
            _gen++;
            _fuzzyTried = false;
            _cliTried = false;
            _errorKind = "";
            _errorDetail = "";
            searchDebounce.restart();
        }

        if (_servedQuery === q) {
            if (_results.length > 0)
                return _results;
            if (_errorKind.length > 0)
                return [_errorRow()];
            if (statsOk && indexedFiles === 0)
                return [_statusRow("empty", "The dsearch index is empty", "Run 'dsearch index generate', then dank-doctext-sync to extract document text", "material:database")];
            var why = documentsOnly ? "Body search matches whole words, not prefixes. Turn off Documents Only to search Markdown notes and transcripts too, or run dank-doctext-sync if the document is new." : "Body search matches whole words, not prefixes. Check the spelling, or run dank-doctext-sync if the document is new.";
            return [_statusRow("empty", "Nothing contains that", why, "material:search_off")];
        }

        return [_statusRow("busy", "Searching documents...", q, "material:hourglass_empty")];
    }

    function executeItem(item) {
        if (!item || item.isStatus)
            return;
        var target = _openTarget(item);
        if (!target)
            return;
        if (item.sourcePath && item.sourceExists === false)
            _toast("The original file is missing, opening the extracted text instead");
        // execDetached with an argv array runs no shell, so spaces, quotes and
        // the U+203A separators in sidecar names need no escaping at all.
        Quickshell.execDetached(["xdg-open", target]);
    }

    // Secondary actions. DMS ignores item.actions for plugin rows and builds
    // both the Tab strip and the right click menu from this function instead
    // (Modals/DankLauncherV2/ActionPanel.qml). Each action has to be a JS
    // function taking no arguments, so fresh closures are built on every call.
    function getContextMenuActions(item) {
        if (!item || item.isStatus)
            return [];

        var target = _openTarget(item);
        if (!target)
            return [];

        var folder = target.substring(0, target.lastIndexOf("/"));
        var actions = [];

        if (folder.length > 0) {
            actions.push({
                "text": "Open containing folder",
                "icon": "folder_open",
                "action": function () {
                    Quickshell.execDetached(["xdg-open", folder]);
                }
            });
        }

        actions.push({
            "text": "Copy path",
            "icon": "content_copy",
            "closeLauncher": true,
            "action": function () {
                Quickshell.execDetached(["dms", "cl", "copy", target]);
            }
        });

        // Only worth offering when the extracted text is a different file from
        // what Enter would open.
        if (item.indexedPath && item.indexedPath !== target) {
            var sidecar = item.indexedPath;
            actions.push({
                "text": "Open extracted text",
                "icon": "article",
                "action": function () {
                    Quickshell.execDetached(["xdg-open", sidecar]);
                }
            });
        }

        return actions;
    }

    // Shift+Enter pastes the path of the original document.
    function getPasteText(item) {
        if (!item || item.isStatus)
            return "";
        return _openTarget(item) || "";
    }

    // ============================================================ search pipeline

    property Timer searchDebounce: Timer {
        // The daemon answers in about 2 ms, so this exists to avoid pointless
        // work while a word is being typed, not to hide latency. DMS already
        // applies its own 60 ms leading edge debounce before getItems is called.
        interval: 120
        repeat: false
        onTriggered: root._startSearch(false, root._gen)
    }

    function _startSearch(useFuzzy, gen) {
        var q = _activeQuery;
        if (q.length < minQueryLength)
            return;
        if (gen === undefined)
            gen = _gen;
        if (gen !== _gen)
            return;

        if (_usable(httpFailedAt)) {
            _httpSearch(q, useFuzzy, gen);
            return;
        }
        if (cliFallback && _usable(dsearchFailedAt)) {
            _cliSearch(q, useFuzzy, gen);
            return;
        }
        _publishError("nodaemon", "", gen);
    }

    // ---- transport 1: the HTTP API

    function _httpSearch(q, useFuzzy, gen) {
        var wire = Math.max(1, Math.min(50, resultLimit));
        var url = apiBase + "/search?field=body&limit=" + wire + "&q=" + encodeURIComponent(q);
        if (documentsOnly)
            url += "&ext=.doctext";
        if (useFuzzy)
            url += "&fuzzy=true";

        var xhr = new XMLHttpRequest();
        _httpJob = {
            "gen": gen,
            "fuzzy": useFuzzy,
            "xhr": xhr
        };

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            // abort() still fires this handler with readyState DONE, so the
            // identity check below is the real cancellation, not abort().
            if (!root._httpJob || root._httpJob.xhr !== xhr)
                return;
            root._httpJob = null;
            if (gen !== root._gen)
                return;
            root._onHttpDone(xhr, useFuzzy, gen);
        };

        try {
            xhr.open("GET", url);
            xhr.send();
            watchdog.restart();
        } catch (e) {
            _httpJob = null;
            _httpTransportFailed(useFuzzy, gen);
        }
    }

    function _onHttpDone(xhr, useFuzzy, gen) {
        // No HTTP response at all: the daemon is down, the listener is off, or
        // the socket was refused. Aborted requests never reach here.
        if (xhr.status === 0) {
            _httpTransportFailed(useFuzzy, gen);
            return;
        }

        if (xhr.status !== 200) {
            var detail = "";
            try {
                var err = JSON.parse(xhr.responseText);
                if (err && err.detail)
                    detail = String(err.detail);
            } catch (e) {}
            if (detail.length === 0)
                detail = "dsearch answered HTTP " + xhr.status;
            _publishError("other", detail, gen);
            return;
        }

        var data = null;
        try {
            data = JSON.parse(xhr.responseText);
        } catch (e2) {
            data = null;
        }
        if (!data) {
            _publishError("other", "dsearch sent a response that could not be parsed", gen);
            return;
        }

        // A reply proves the daemon is alive, so anything the cooldown was
        // holding against it is stale.
        httpFailedAt = 0;
        statsOk = true;
        _consumeSearch(data, useFuzzy, gen);
    }

    function _httpTransportFailed(useFuzzy, gen) {
        httpFailedAt = Date.now();
        statsOk = false;
        statsProbedAt = 0;      // let the next activation re-probe immediately

        if (cliFallback && !_cliTried && _usable(dsearchFailedAt)) {
            _cliTried = true;
            _cliSearch(_activeQuery, useFuzzy, gen);
            return;
        }
        _publishError("nodaemon", "", gen);
    }

    // ---- transport 2: the dsearch binary, which reaches the same daemon

    function _cliSearch(q, useFuzzy, gen) {
        // Exactly the flags the HTTP request carries, so the answer does not
        // change shape depending on which transport happened to win. The query
        // goes last, behind "--", so a term beginning with a dash is never
        // parsed as a flag.
        var args = ["dsearch", "search", "--json", "-f", "body", "-n", String(Math.max(1, Math.min(50, resultLimit)))];
        if (documentsOnly)
            args.push("-e", ".doctext");
        if (useFuzzy)
            args.push("--fuzzy");
        args.push("--", q);

        _queueJob(jobSearch, args, gen, useFuzzy);
    }

    function _onSearchDone(stdout, stderrText, exitCode, useFuzzy, gen) {
        var response = null;
        try {
            response = JSON.parse(stdout);
        } catch (e) {
            response = null;
        }

        if (exitCode !== 0 || !response) {
            var failure = _classifyError(stderrText, exitCode);
            _publishError(failure.kind, failure.detail, gen);
            return;
        }

        dsearchFailedAt = 0;
        _consumeSearch(response, useFuzzy, gen);
    }

    // ---- shared by both transports

    function _consumeSearch(response, useFuzzy, gen) {
        if (gen !== _gen)
            return;

        var q = _activeQuery;

        // dsearch returns null rather than [] for hits on some paths.
        var hits = Array.isArray(response.hits) ? response.hits : [];

        // Exact body search is deliberately strict: a word that appears nowhere
        // in the corpus returns nothing at all. Retry once with edit distance
        // matching, which recovers typos, before reporting no results. Short
        // queries are excluded because fuzzy matching turns them into noise.
        if (hits.length === 0 && fuzzyFallback && !_fuzzyTried && !useFuzzy && q.length >= 5) {
            _fuzzyTried = true;
            _startSearch(true, gen);
            return;
        }

        var rows = [];
        for (var i = 0; i < hits.length; i++) {
            var row = _makeRow(hits[i], i);
            if (row)
                rows.push(row);
        }

        _results = rows;
        _servedQuery = q;
        _errorKind = "";
        _errorDetail = "";
        _publish();

        if (rows.length === 0 || !_usable(resolveFailedAt)) {
            watchdog.stop();
            return;
        }

        // Stage 2. Mapping only, for every hit. Three milliseconds for twenty
        // files, so the correct filenames replace the guessed ones almost at
        // once.
        var paths = [];
        for (var j = 0; j < rows.length; j++)
            paths.push(rows[j].indexedPath);

        _queueJob(jobMap, ["awk", "-f", resolveScript, "", "0"].concat(paths), gen);
    }

    function _onMapDone(stdout, gen) {
        // Work out the needle before publishing. _applyResolved calls _publish,
        // which re-enters getItems, which can move _activeQuery on to whatever
        // is in the search box by then. The snippet has to be scanned for the
        // query these results belong to, not that one.
        var needle = showSnippets ? _snippetNeedle(_activeQuery) : "";

        resolveFailedAt = 0;
        _applyResolved(stdout);

        if (needle.length === 0 || snippetBudget <= 0 || _results.length === 0) {
            watchdog.stop();
            return;
        }

        // Stage 3. Only the leading hits, because this one actually reads the
        // extracted bodies and those run to several megabytes each.
        var budget = Math.min(snippetBudget, _results.length);
        var paths = [];
        for (var i = 0; i < budget; i++)
            paths.push(_results[i].indexedPath);

        _queueJob(jobSnippet, ["awk", "-f", resolveScript, needle, String(budget)].concat(paths), gen);
    }

    function _onSnippetDone(stdout, gen) {
        watchdog.stop();
        resolveFailedAt = 0;
        _applyResolved(stdout);
    }

    // Both awk stages emit the same two line types, so one parser handles them.
    //   M <indexedPath> <sourcePath> <0|1>
    //   S <indexedPath> <snippet>
    function _applyResolved(stdout) {
        var byPath = {};
        var lines = (stdout || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].length === 0)
                continue;
            var f = lines[i].split("\t");
            if (f.length < 3)
                continue;
            var path = f[1];
            if (!byPath[path])
                byPath[path] = {};
            if (f[0] === "M") {
                byPath[path].source = f[2];
                byPath[path].exists = f.length > 3 && f[3] === "1";
            } else if (f[0] === "S") {
                // Rejoin in case a snippet ever contains a tab. The awk side
                // strips them, so this is belt and braces.
                byPath[path].snippet = f.slice(2).join("\t");
            }
        }

        // Mutate the existing rows rather than rebuilding them. Their ids stay
        // identical, which keeps the launcher selection where the user put it
        // across a republish: Controller.preserveSelectionAfterUpdate matches
        // on item.id.
        //
        // Republish only when the launcher would draw something different. The
        // snippet stage re-reports the mapping the mapping stage already found,
        // and a snippet is not always shown, so without this check some
        // searches would cost an extra full rebuild for an identical list. The
        // three fields compared here are exactly the ones a row renders with.
        var changed = false;
        for (var r = 0; r < _results.length; r++) {
            var row = _results[r];
            var info = byPath[row.indexedPath];
            if (!info)
                continue;

            var wasName = row.name;
            var wasIcon = row.icon;
            var wasComment = row.comment;

            if (info.source !== undefined) {
                if (info.source.length > 0) {
                    // A sidecar with a usable header. That header is
                    // authoritative, so the name guessed from the flattened
                    // filename is replaced here, and the icon with it since it
                    // was picked from the guess.
                    row.sourcePath = info.source;
                    row.name = _basename(info.source);
                    row.icon = _iconFor(info.source);
                } else {
                    // Either a plain text file that dsearch indexed directly,
                    // or a sidecar with no header. In both cases the indexed
                    // file is the document. exists goes false only when the
                    // file itself could not be opened at all.
                    row.sourcePath = row.indexedPath;
                }
                row.sourceExists = info.exists === true;
                row.resolved = true;
            }

            if (info.snippet !== undefined && info.snippet.length > 0)
                row.snippet = info.snippet;

            row.comment = _subtitleFor(row);

            if (row.name !== wasName || row.icon !== wasIcon || row.comment !== wasComment)
                changed = true;
        }

        if (_dedupeResolved())
            changed = true;

        if (changed)
            _publish();
    }

    // A PDF and the Markdown it was rendered from are two indexed files holding
    // the same words, and both match. Once the mapping stage has told us what
    // each row really points at, collapse them and keep the higher scoring one,
    // which is already first.
    //
    // Only rows that have actually been resolved take part. Two rows that are
    // both still waiting on the mapping stage have no comparable source path,
    // and folding them together on a guess would delete a real result. That
    // conflation is exactly what made the other candidate lose documents.
    function _dedupeResolved() {
        var seen = {};
        var kept = [];
        var removed = false;

        for (var i = 0; i < _results.length; i++) {
            var row = _results[i];
            if (!row.resolved || !row.sourcePath || row.sourcePath.length === 0) {
                kept.push(row);
                continue;
            }
            if (seen[row.sourcePath]) {
                removed = true;
                continue;
            }
            seen[row.sourcePath] = true;
            kept.push(row);
        }

        if (removed)
            _results = kept;
        return removed;
    }

    // ============================================================ process plumbing

    property Process job: Process {
        id: jobProc
        running: false
        stdout: StdioCollector {
            id: jobOut
            onStreamFinished: {
                root._outDone = true;
                root._maybeComplete();
            }
        }
        stderr: StdioCollector {
            id: jobErr
            onStreamFinished: {
                root._errDone = true;
                root._maybeComplete();
            }
        }
        onExited: code => {
            root._exitCode = code;
            root._exitDone = true;
            root._maybeComplete();
        }
        onRunningChanged: {
            // When a binary does not exist, Quickshell logs a warning and sets
            // running back to false without ever emitting exited or
            // streamFinished. Measured at four milliseconds. This transition is
            // the only notification of that, so adjudicate shortly after it
            // rather than waiting for the six second watchdog.
            if (!jobProc.running && root._jobKind !== root.jobNone)
                startCheck.restart();
        }
    }

    property Timer startCheck: Timer {
        // Short, but long enough that a normally exiting process has delivered
        // its signals: running goes false in the same millisecond as exited.
        interval: 150
        repeat: false
        onTriggered: {
            if (root._jobKind === root.jobNone)
                return;             // already completed
            if (root._stopRequested)
                return;             // stopped on purpose
            if (root._outDone || root._errDone || root._exitDone)
                return;             // it clearly started, just has not finished
            if (jobProc.running)
                return;             // running again already

            var failedKind = root._jobKind;
            var failedGen = root._jobGen;
            root._jobKind = root.jobNone;
            root.watchdog.stop();

            // Every branch below records a timestamp rather than turning the
            // path off. The next launcher activation clears it, and a cooldown
            // clears it even without one, so a missing binary that is installed
            // later starts working without reloading the plugin.
            if (failedKind === root.jobSearch) {
                root.dsearchFailedAt = Date.now();
                root._publishError("nobinary", "", failedGen);
            } else {
                // Results are already on screen. Stop attempting the awk stages
                // for now rather than spending a failed launch on every later
                // query.
                root.resolveFailedAt = Date.now();
            }
        }
    }

    property Timer watchdog: Timer {
        // The backstop for the one failure a generation counter cannot see: a
        // request that starts and then never finishes. Neither Quickshell's
        // Process nor QML's XMLHttpRequest has a built in timeout, so this
        // timer is the only cover for both.
        interval: 6000
        repeat: false
        onTriggered: root._onWatchdog()
    }

    property Timer launchTimer: Timer {
        // Only used while waiting for a child that was asked to stop.
        interval: 25
        repeat: false
        onTriggered: root._launchPending()
    }

    // Process.command must never be assigned while the process is running, so
    // _queueJob puts the request in a single pending slot, asks any current
    // child to stop, and lets whoever frees the slot start it.
    function _queueJob(kind, cmd, gen, fuzzy) {
        _pending = {
            "kind": kind,
            "cmd": cmd,
            "gen": gen,
            "fuzzy": fuzzy === true
        };
        _launchRetries = 0;
        watchdog.restart();

        if (_jobKind !== jobNone || jobProc.running) {
            if (jobProc.running) {
                _stopRequested = true;
                jobProc.running = false;
            }
            launchTimer.restart();
            return;
        }

        _launchPending();
    }

    function _launchPending() {
        if (!_pending)
            return;

        // A newer query arrived while this one waited for the slot.
        if (_pending.gen !== _gen) {
            _pending = null;
            return;
        }

        if (jobProc.running) {
            _launchRetries++;
            if (_launchRetries > 80) {
                var stuckGen = _pending.gen;
                _pending = null;
                _publishError("stuck", "", stuckGen);
                return;
            }
            launchTimer.restart();
            return;
        }

        var next = _pending;
        _pending = null;

        _jobKind = next.kind;
        _jobGen = next.gen;
        _jobFuzzy = next.fuzzy === true;
        _stopRequested = false;
        _outDone = false;
        _errDone = false;
        _exitDone = false;
        _exitCode = -1;
        startCheck.stop();
        jobProc.command = next.cmd;
        jobProc.running = true;
    }

    function _maybeComplete() {
        if (!_outDone || !_errDone || !_exitDone)
            return;

        var kind = _jobKind;
        var gen = _jobGen;
        var fuzzy = _jobFuzzy;
        var code = _exitCode;
        var out = "";
        var err = "";
        try {
            out = jobOut.text || "";
            err = jobErr.text || "";
        } catch (e) {
            out = "";
            err = "";
        }

        // Free the slot before dispatching. A callback may queue the next
        // stage, and it has to find the slot idle. Relaunching the same Process
        // from inside its own completion handler is safe and the collectors
        // reset per launch, which is what makes the chain work.
        startCheck.stop();
        _jobKind = jobNone;
        _outDone = false;
        _errDone = false;
        _exitDone = false;

        if (_pending) {
            // A newer query superseded this one while it ran. Start that and
            // throw away the output that just landed.
            _launchPending();
            return;
        }

        if (kind === jobNone)
            return;

        // Late output from a superseded query.
        if (gen !== _gen)
            return;

        if (kind === jobSearch)
            _onSearchDone(out, err, code, fuzzy, gen);
        else if (kind === jobMap)
            _onMapDone(out, gen);
        else if (kind === jobSnippet)
            _onSnippetDone(out, gen);
    }

    function _onWatchdog() {
        startCheck.stop();

        // An HTTP request that never finished. Treat it exactly like a refused
        // connection: record the failure and let the CLI fallback try.
        if (_httpJob) {
            var httpGen = _httpJob.gen;
            var httpFuzzy = _httpJob.fuzzy;
            var xhr = _httpJob.xhr;
            _httpJob = null;
            try {
                xhr.abort();
            } catch (e) {}
            _httpTransportFailed(httpFuzzy, httpGen);
            return;
        }

        var kind = _jobKind;
        var gen = _jobGen;

        if (jobProc.running) {
            _stopRequested = true;
            jobProc.running = false;
        }
        _jobKind = jobNone;
        _pending = null;

        if (kind === jobSearch) {
            dsearchFailedAt = Date.now();
            _publishError("timeout", "", gen);
            return;
        }

        // Results are already on screen. Losing an enrichment pass is not worth
        // an error row, but a stage that wedges once will probably wedge again,
        // so stop asking for it until the cooldown expires.
        if (kind !== jobNone)
            resolveFailedAt = Date.now();
    }

    function _cancel() {
        // Idempotent. getItems calls this on every keystroke below the minimum
        // length, so it must be free when there is nothing to cancel.
        if (_jobKind === jobNone && !_pending && !_httpJob && !jobProc.running && _activeQuery.length === 0 && _servedQuery.length === 0 && _results.length === 0)
            return;

        searchDebounce.stop();
        launchTimer.stop();
        watchdog.stop();
        startCheck.stop();
        _pending = null;
        _jobKind = jobNone;
        // Invalidates every callback still in flight.
        _gen++;
        _activeQuery = "";
        _servedQuery = "";
        _results = [];
        _errorKind = "";
        _errorDetail = "";
        _fuzzyTried = false;
        _cliTried = false;
        if (_httpJob) {
            var xhr = _httpJob.xhr;
            _httpJob = null;
            try {
                xhr.abort();
            } catch (e) {}
        }
        if (jobProc.running) {
            _stopRequested = true;
            jobProc.running = false;
        }
    }

    function _publish() {
        itemsChanged();
        if (pluginService && typeof pluginService.requestLauncherUpdate === "function")
            pluginService.requestLauncherUpdate(pluginId);
    }

    // gen is the generation the failure belongs to. Without it a slow failure
    // path, the start check and the watchdog above in particular, could stamp
    // an error row onto a query the user has already moved past, and that row
    // would then stick because getItems only clears the error when the query
    // changes again.
    function _publishError(kind, detail, gen) {
        if (gen !== undefined && gen !== _gen)
            return;
        watchdog.stop();
        _results = [];
        _servedQuery = _activeQuery;
        _errorKind = kind || "other";
        _errorDetail = detail || "";
        _publish();
    }

    // dsearch writes progress on stderr as "  INFO ..." and failures as
    // " FATAL ...", so the first line is usually noise rather than the reason.
    // Find the failure line, and turn the two cases worth acting on into their
    // own kind so the row can say what to do about them.
    function _classifyError(stderrText, exitCode) {
        var lines = String(stderrText || "").split("\n");
        var fatal = "";
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("FATAL") !== -1 || lines[i].indexOf("ERROR") !== -1) {
                fatal = lines[i];
                break;
            }
        }

        if (fatal.indexOf("index is empty") !== -1)
            return {
                "kind": "emptyindex",
                "detail": ""
            };
        if (fatal.indexOf("server not running") !== -1 || fatal.indexOf("connection refused") !== -1)
            return {
                "kind": "nodaemon",
                "detail": ""
            };

        var detail = fatal.replace(/^\s*(FATAL|ERROR)\s*/, "").trim();
        if (detail.length === 0)
            detail = "dsearch exited with code " + exitCode;
        return {
            "kind": "other",
            "detail": detail
        };
    }

    function _errorRow() {
        switch (_errorKind) {
        case "nobinary":
            return _statusRow("err", "dsearch is not installed", "The HTTP API did not answer either. Install dsearch and start it with 'dsearch serve'.", "material:error_outline");
        case "emptyindex":
            return _statusRow("err", "The dsearch index is empty", "Run 'dsearch index generate', then dank-doctext-sync to extract document text", "material:database");
        case "nodaemon":
            return _statusRow("err", "The dsearch service is not answering", "Nothing is listening on 127.0.0.1:43654. Start it with 'dsearch serve', or 'systemctl --user start danksearch'.", "material:cloud_off");
        case "timeout":
            return _statusRow("err", "dsearch did not answer", "It did not respond within six seconds. Check that the service is healthy.", "material:timer_off");
        case "stuck":
            return _statusRow("err", "The previous search would not stop", "Reload the plugin with 'dms ipc call plugin-scan reload docSearch'", "material:error_outline");
        default:
            return _statusRow("err", "Search failed", _errorDetail, "material:error_outline");
        }
    }

    // ============================================================ row building

    function _makeRow(hit, index) {
        var path = hit && hit.id ? String(hit.id) : "";
        if (path.length === 0)
            return null;

        // Sidecars are identified by extension rather than by location. dsearch
        // is configured with the cache directory in its index, but the plugin
        // has no business assuming where that is, and stage 2 confirms the
        // guess anyway by either finding a source header or not.
        var isSidecar = path.length > 8 && path.lastIndexOf(".doctext") === path.length - 8;

        // Provisional only. The flattened sidecar filename decodes correctly
        // about 96 percent of the time, and stage 2 overwrites it three
        // milliseconds later. It matters when awk is unavailable, which is the
        // only case where this name is what the user ends up reading.
        var provisional = isSidecar ? _decodeSidecarName(path) : _basename(path);

        var row = {
            // Stable across all three publishes, so the selection does not jump
            // when a later stage lands.
            "id": "docSearch:" + path,
            "indexedPath": path,
            "isSidecar": isSidecar,
            "resolved": false,
            "sourcePath": isSidecar ? "" : path,
            "sourceExists": true,
            "snippet": "",
            "score": hit.score || 0,
            "name": provisional,
            "icon": _iconFor(provisional),
            "comment": "",
            "categories": ["Document Search"],
            // The launcher drops any item whose name, subtitle or keywords do
            // not textually match the query: Scorer.js returns 0 for those and
            // scoreItems then skips them. A body match lives in the file
            // contents, not the filename, so without _preScored every result
            // here would be filtered away. The value also carries the backend
            // ranking through, since scored items sort descending. Even at the
            // maximum limit of 50 the lowest value is 951, which stays above
            // the 900 threshold Scorer.js uses when the query is empty.
            "_preScored": 1000 - index,
            "primaryAction": {
                "name": "Open document",
                "icon": "open_in_new",
                "action": "execute"
            }
        };
        row.comment = _subtitleFor(row);
        return row;
    }

    function _subtitleFor(row) {
        if (row.sourcePath && row.sourcePath.length > 0 && row.sourceExists === false)
            return "Original file is missing: " + _shortenHome(row.sourcePath);
        if (row.snippet && row.snippet.length > 0)
            return row.snippet;
        if (row.isSidecar && !row.resolved)
            return _decodeSidecarFolder(row.indexedPath);
        var p = row.sourcePath && row.sourcePath.length > 0 ? row.sourcePath : row.indexedPath;
        return _shortenHome(_dirname(p));
    }

    function _statusRow(id, name, comment, icon) {
        return {
            "id": "docSearch:status:" + id,
            "isStatus": true,
            "name": name,
            "comment": comment,
            "icon": icon,
            "categories": ["Document Search"],
            "_preScored": 1000
        };
    }

    function _openTarget(item) {
        if (item.sourcePath && item.sourcePath.length > 0 && item.sourceExists !== false)
            return item.sourcePath;
        // Falls back to the sidecar. ~/.local/bin/dank-doctext-open is
        // registered as the handler for *.doctext, so opening it re-reads the
        // header and still lands on the original when the mapping has simply
        // not been resolved yet, and shows the extracted text when the original
        // is really gone.
        return item.indexedPath || "";
    }

    // ============================================================ path helpers

    function _basename(p) {
        if (!p)
            return "";
        var i = p.lastIndexOf("/");
        return i === -1 ? p : p.substring(i + 1);
    }

    function _dirname(p) {
        if (!p)
            return "";
        var i = p.lastIndexOf("/");
        return i <= 0 ? "/" : p.substring(0, i);
    }

    function _shortenHome(p) {
        if (!p)
            return "";
        if (homeDir.length > 0 && p.indexOf(homeDir + "/") === 0)
            return "~" + p.substring(homeDir.length);
        return p;
    }

    // Sidecar filenames flatten the source path with " > " (U+203A) separators.
    // dank-doctext-sync truncates and hashes anything longer than NAME_MAX, so
    // this is right most of the time but not always. It is only ever a
    // placeholder; stage 2 replaces it with the path from the header line.
    function _decodeSidecarName(path) {
        var base = _basename(path);
        if (base.lastIndexOf(".doctext") === base.length - 8)
            base = base.substring(0, base.length - 8);
        var parts = base.split(" › ");
        var name = parts[parts.length - 1];
        // A truncated name carries an eight digit hex disambiguator after the
        // extension. Drop it so the placeholder still gets the right icon.
        return name.replace(/^(.*\.[A-Za-z0-9]{1,5}) [0-9a-f]{8}$/, "$1");
    }

    function _decodeSidecarFolder(path) {
        var base = _basename(path);
        if (base.lastIndexOf(".doctext") === base.length - 8)
            base = base.substring(0, base.length - 8);
        var parts = base.split(" › ");
        if (parts.length < 2)
            return "~";
        return "~/" + parts.slice(0, parts.length - 1).join("/");
    }

    function _iconFor(p) {
        var lower = (p || "").toLowerCase();
        var dot = lower.lastIndexOf(".");
        var ext = dot === -1 ? "" : lower.substring(dot + 1);
        switch (ext) {
        case "pdf":
            return "material:picture_as_pdf";
        case "epub":
            return "material:menu_book";
        case "docx":
        case "doc":
        case "odt":
        case "rtf":
            return "material:description";
        case "pptx":
        case "ppt":
        case "odp":
            return "material:co_present";
        case "md":
        case "markdown":
        case "txt":
        case "org":
            return "material:article";
        default:
            return "material:draft";
        }
    }

    // The index matches whole tokens and ORs a multi word query, so the longest
    // token is picked for the snippet scan: it is the most distinctive one and
    // the most likely to actually be in the file that matched.
    function _snippetNeedle(q) {
        var tokens = q.toLowerCase().split(/\s+/);
        var best = "";
        for (var i = 0; i < tokens.length; i++) {
            var t = tokens[i].replace(/^["'(\[{]+/, "").replace(/["')\]}.,;:!?]+$/, "");
            if (t.length >= 3 && t.length > best.length)
                best = t;
        }
        return best;
    }

    // ToastService.showWarning takes (message, details), not a title.
    function _toast(message) {
        if (typeof ToastService !== "undefined")
            ToastService.showWarning(message);
    }

    // ============================================================ settings glue

    function loadSettings() {
        if (!pluginService)
            return;

        noTrigger = pluginService.loadPluginData(pluginId, "noTrigger", false) === true;
        trigger = pluginService.loadPluginData(pluginId, "trigger", "#") || "#";

        // Keep the launcher's own "show without a trigger" flag in step with the
        // plugin setting. Left at its default of true, every launcher query of
        // two or more characters would call getItems and query dsearch, which is
        // not what anyone wants from a document search.
        if (SettingsData.getPluginAllowWithoutTrigger(pluginId) !== noTrigger)
            SettingsData.setPluginAllowWithoutTrigger(pluginId, noTrigger);

        resultLimit = _clampInt(pluginService.loadPluginData(pluginId, "resultLimit", 20), 1, 50, 20);
        minQueryLength = _clampInt(pluginService.loadPluginData(pluginId, "minQueryLength", 3), 2, 10, 3);
        snippetBudget = _clampInt(pluginService.loadPluginData(pluginId, "snippetBudget", 5), 0, 25, 5);
        showSnippets = pluginService.loadPluginData(pluginId, "showSnippets", true) === true;
        fuzzyFallback = pluginService.loadPluginData(pluginId, "fuzzyFallback", true) === true;
        documentsOnly = pluginService.loadPluginData(pluginId, "documentsOnly", false) === true;
        cliFallback = pluginService.loadPluginData(pluginId, "cliFallback", true) === true;
    }

    function _clampInt(value, lo, hi, fallback) {
        var n = parseInt(value, 10);
        if (isNaN(n))
            return fallback;
        return Math.max(lo, Math.min(hi, n));
    }

    property Connections settingsConn: Connections {
        target: root.pluginService
        enabled: root.pluginService !== null
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId)
                return;
            try {
                root.loadSettings();
            } catch (e) {
                console.warn("docSearch: settings reload failed:", e);
            }
            // Anything that changes the query shape invalidates the cache.
            root._cancel();
        }
    }

    Component.onCompleted: {
        // No settings are written here. The manifest's trigger is already the
        // default that PluginService.getPluginTrigger falls back to, so seeding
        // plugin_settings.json would only rewrite the whole file and fire
        // pluginDataChanged for no gain.
        try {
            loadSettings();
        } catch (e) {
            console.warn("docSearch: settings load failed, using defaults:", e);
        }
        _probeStats();
    }
}
