// Minimal niri IPC client: subscribes to the event stream on $NIRI_SOCKET
// and exposes workspaces + focused window title as reactive Variables.
// Protocol: newline-delimited JSON; request `"EventStream"` streams events.
// https://yalter.github.io/niri/niri_ipc/

import { Variable, execAsync } from "astal"
import Gio from "gi://Gio"
import GLib from "gi://GLib"

export interface Workspace {
    id: number
    idx: number
    name: string | null
    output: string
    is_active: boolean
    is_focused: boolean
}

interface NiriWindow {
    id: number
    title: string | null
    app_id: string | null
    is_focused: boolean
}

export const workspaces: Variable<Workspace[]> = Variable([])
export const focusedTitle: Variable<string> = Variable("")

const windows = new Map<number, NiriWindow>()
let focusedWindow: number | null = null

export function focusWorkspace(idx: number) {
    execAsync(["niri", "msg", "action", "focus-workspace", String(idx)])
        .catch(err => console.error("niri focus-workspace:", err))
}

function syncTitle() {
    const win = focusedWindow !== null ? windows.get(focusedWindow) : undefined
    focusedTitle.set(win?.title ?? "")
}

function sortWs(list: Workspace[]): Workspace[] {
    return [...list].sort((a, b) =>
        a.output.localeCompare(b.output) || a.idx - b.idx)
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function handle(event: any) {
    if ("WorkspacesChanged" in event) {
        workspaces.set(sortWs(event.WorkspacesChanged.workspaces))
    } else if ("WorkspaceActivated" in event) {
        const { id, focused } = event.WorkspaceActivated
        const target = workspaces.get().find(w => w.id === id)
        if (!target) return
        workspaces.set(workspaces.get().map(w => ({
            ...w,
            is_active: w.output === target.output ? w.id === id : w.is_active,
            is_focused: focused ? w.id === id : (w.id === id ? false : w.is_focused),
        })))
    } else if ("WindowsChanged" in event) {
        windows.clear()
        focusedWindow = null
        for (const w of event.WindowsChanged.windows as NiriWindow[]) {
            windows.set(w.id, w)
            if (w.is_focused) focusedWindow = w.id
        }
        syncTitle()
    } else if ("WindowOpenedOrChanged" in event) {
        const w = event.WindowOpenedOrChanged.window as NiriWindow
        windows.set(w.id, w)
        if (w.is_focused) focusedWindow = w.id
        syncTitle()
    } else if ("WindowClosed" in event) {
        const id = event.WindowClosed.id as number
        windows.delete(id)
        if (focusedWindow === id) focusedWindow = null
        syncTitle()
    } else if ("WindowFocusChanged" in event) {
        focusedWindow = event.WindowFocusChanged.id ?? null
        syncTitle()
    }
}

function connect() {
    const path = GLib.getenv("NIRI_SOCKET")
    if (!path) {
        console.error("niri.ts: NIRI_SOCKET is not set; workspaces disabled")
        return
    }

    try {
        const client = new Gio.SocketClient()
        const conn = client.connect(new Gio.UnixSocketAddress({ path }), null)

        conn.get_output_stream()
            .write_all(new TextEncoder().encode('"EventStream"\n'), null)

        const stream = new Gio.DataInputStream({
            base_stream: conn.get_input_stream(),
        })

        const loop = () => {
            stream.read_line_async(GLib.PRIORITY_DEFAULT, null, (src, res) => {
                try {
                    const [line] = src!.read_line_finish(res)
                    if (line === null) throw new Error("niri socket EOF")
                    const text = new TextDecoder().decode(line).trim()
                    if (text.length > 0) handle(JSON.parse(text))
                    loop()
                } catch (err) {
                    console.error("niri.ts: stream error, reconnecting:", err)
                    setTimeout(connect, 2000)
                }
            })
        }
        loop()
    } catch (err) {
        console.error("niri.ts: connect failed, retrying:", err)
        setTimeout(connect, 2000)
    }
}

connect()
