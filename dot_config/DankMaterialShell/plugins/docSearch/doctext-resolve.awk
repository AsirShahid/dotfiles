# doctext-resolve.awk
#
# Stage 2 of the Document Search plugin. Turns the file paths that dsearch
# matched into everything the launcher needs to draw a row, in one process.
#
# Invocation. Every value is a separate argv element and nothing goes through a
# shell, so paths containing spaces, quotes or the U+203A separators used in
# sidecar names need no escaping:
#
#     awk -f doctext-resolve.awk <needle> <snippetBudget> <file1> <file2> ...
#
#   needle         lowercased word to look for in the body, or "" to skip
#                  snippet extraction entirely
#   snippetBudget  how many of the leading files may be scanned for a snippet
#   fileN          absolute paths, exactly as dsearch reported them
#
# Output is tab separated, one or two lines per input file:
#
#     M<TAB>path<TAB>sourcePath<TAB>0|1   mapping, and whether the source opens
#     S<TAB>path<TAB>snippet              only when the needle was found
#
# sourcePath is empty for a file that is not a doctext sidecar. That is the
# right answer for those: the indexed file is the original.
#
# The whole program runs in BEGIN and then exits, so awk never treats the paths
# as file operands. That is deliberate. As an operand, a path that no longer
# exists makes gawk print "fatal: cannot open file" and abort the entire run,
# which would silently drop every hit listed after the first deleted sidecar.
# Read explicitly with getline instead and a missing file returns -1, so the
# rest of the batch still gets processed.

function probeExists(path,    savedRS, rc, junk) {
    # An existence test that reads at most one byte. With RS set to the regex
    # "." every single character is a record separator, so getline stops after
    # the first one instead of scanning for a newline. That matters because the
    # originals are PDFs and EPUBs: an EPUB is a zip, and its first newline can
    # be megabytes in, which a plain getline would read in full.
    savedRS = RS
    RS = "."
    rc = (getline junk < path)
    RS = savedRS
    close(path)
    return (rc >= 0) ? 1 : 0
}

function clean(s) {
    gsub(/[\t\r\n]+/, " ", s)
    return s
}

function findSnippet(line, needle,    pos, start, out) {
    pos = index(tolower(line), needle)
    if (pos <= 0)
        return ""
    # Keep the match near the front of the excerpt. A launcher subtitle is one
    # truncated line, so a match centred in 160 characters falls off the right
    # edge on a narrow launcher.
    start = pos - 32
    if (start < 1)
        start = 1
    out = clean(substr(line, start, 160))
    return (start > 1) ? "..." out : out
}

function resolve(path, rank,    rc, line1, src, wantSnippet, snippet, guard, exists) {
    # An empty path would make the "<" redirection itself fatal, which is the
    # one remaining way this program could abort. Never pass one, but do not
    # depend on the caller for it.
    if (path == "")
        return

    rc = (getline line1 < path)
    if (rc < 0) {
        # The indexed file itself is gone. Report it so the caller can mark the
        # row rather than offering to open something that is not there.
        print "M", path, "", 0
        return
    }

    src = ""
    if (index(line1, HDR) == 1)
        src = substr(line1, length(HDR) + 1)

    wantSnippet = (needle != "" && rank <= budget)
    snippet = ""

    if (wantSnippet) {
        # For a sidecar, line 1 is the header just consumed, so skip it: the
        # source path is not body text and matching it would be misleading. For
        # a plain text file there is no header and line 1 is real content.
        if (src == "")
            snippet = findSnippet(line1, needle)

        guard = 0
        while (snippet == "" && guard < 20000 && (getline line1 < path) > 0) {
            guard++
            snippet = findSnippet(line1, needle)
        }
    }

    close(path)

    exists = (src != "") ? probeExists(src) : 1
    print "M", path, clean(src), exists
    if (snippet != "")
        print "S", path, snippet
}

BEGIN {
    HDR = "# dank-doctext-source: "
    OFS = "\t"

    needle = ARGV[1]
    budget = ARGV[2] + 0

    for (i = 3; i < ARGC; i++)
        resolve(ARGV[i], i - 2)

    exit 0
}
