// Transient notification popups (top-right) + a bottom-center OSD.
//
// The OSD reuses the `niri-osd` script's notify-send messages: when a
// notification arrives from app "niri-osd", we render it as a progress OSD
// (parsed from its summary, e.g. "Volume 45%") instead of a normal card,
// and dismiss it so it never lands in the notification list. That gives a
// native OSD in AGS mode with the exact same key bindings used in the
// waybar/swaync fallback.

import { App, Astal, Gtk } from "astal/gtk4"
import { Variable, bind, timeout } from "astal"
import { notifd } from "../lib/services"
import NotificationCard from "./Notification"

const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor

// ── OSD ────────────────────────────────────────────────────────────────

const osd = Variable<{ icon: string; label: string; value: number } | null>(null)
let osdToken = 0

function showOsd(summary: string, appIcon: string) {
    const m = summary.match(/(-?\d+)\s*%/)
    const value = m ? Math.max(0, Math.min(100, Number(m[1]))) / 100 : 0
    const lower = summary.toLowerCase()
    const icon = appIcon && appIcon.length > 0 ? appIcon
        : lower.includes("bright") ? "display-brightness-symbolic"
            : lower.includes("mut") ? "audio-volume-muted-symbolic"
                : lower.includes("mic") ? "microphone-sensitivity-high-symbolic"
                    : "audio-volume-high-symbolic"

    osd.set({ icon, label: summary, value })
    const token = ++osdToken
    timeout(1400, () => { if (token === osdToken) osd.set(null) })
}

function Osd() {
    return <window
        cssClasses={["osd-window"]}
        namespace="niri-osd"
        anchor={BOTTOM}
        marginBottom={90}
        layer={Astal.Layer.OVERLAY}
        visible={bind(osd).as(o => o !== null)}
        application={App}>
        <box cssClasses={["osd"]} spacing={12}>
            <image iconName={bind(osd).as(o => o?.icon ?? "")} pixelSize={22} />
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}
                valign={Gtk.Align.CENTER} widthRequest={210}>
                <label cssClasses={["osd-label"]} halign={Gtk.Align.START}
                    label={bind(osd).as(o => o?.label ?? "")} />
                <levelbar cssClasses={["osd-bar"]}
                    value={bind(osd).as(o => o?.value ?? 0)} />
            </box>
        </box>
    </window>
}

// ── Popups ─────────────────────────────────────────────────────────────

// Ids currently shown as popups, newest first.
const popups = Variable<number[]>([])

function Popups() {
    return <window
        cssClasses={["notifications-window"]}
        namespace="niri-notifications"
        anchor={TOP | RIGHT}
        layer={Astal.Layer.OVERLAY}
        application={App}>
        <box cssClasses={["notifications"]}
            orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            {bind(popups).as(ids => ids
                .map(id => notifd?.get_notification(id))
                .filter((n): n is NonNullable<typeof n> => !!n)
                .map(n => NotificationCard(n)))}
        </box>
    </window>
}

export default function Notifications() {
    if (!notifd) {
        console.error("Notifications: AstalNotifd unavailable")
        return
    }

    notifd.connect("notified", (_, id, replaced) => {
        const n = notifd!.get_notification(id)
        if (!n) return

        // OSD channel — render specially, keep it out of the list/popups.
        if (n.appName === "niri-osd") {
            showOsd(n.summary, n.appIcon)
            n.dismiss()
            return
        }

        if (!replaced) popups.set([id, ...popups.get()])
        // Auto-expire non-critical popups; they stay in the center until
        // dismissed there.
        if (n.urgency !== 2 /* CRITICAL */) {
            timeout(6000, () => popups.set(popups.get().filter(x => x !== id)))
        }
    })

    notifd.connect("resolved", (_, id) => {
        popups.set(popups.get().filter(x => x !== id))
    })

    Osd()
    Popups()
}
