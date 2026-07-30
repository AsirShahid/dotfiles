// One notification card, shared by the transient popups and the Quick
// Settings list.

import { Gtk } from "astal/gtk4"
import GLib from "gi://GLib"
import { type AstalNotifd } from "../lib/services"

type Notification = AstalNotifd.Notification

function urgencyClass(n: Notification): string {
    switch (n.urgency) {
        case 2: return "critical"   // AstalNotifd.Urgency.CRITICAL
        case 0: return "low"        // AstalNotifd.Urgency.LOW
        default: return "normal"
    }
}

function time(n: Notification): string {
    return GLib.DateTime.new_from_unix_local(n.time).format("%I:%M %p") ?? ""
}

function icon(n: Notification) {
    if (n.image && n.image.length > 0)
        return <image cssClasses={["app-image"]} file={n.image} pixelSize={40} />
    return <image cssClasses={["app-icon"]}
        iconName={n.appIcon && n.appIcon.length > 0
            ? n.appIcon : "dialog-information-symbolic"}
        pixelSize={28} />
}

export default function NotificationCard(n: Notification) {
    return <box
        cssClasses={["notification", urgencyClass(n)]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={6}>
        <box spacing={10}>
            {icon(n)}
            <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                <box spacing={6}>
                    <label cssClasses={["app-name"]} halign={Gtk.Align.START}
                        hexpand label={n.appName || "Notification"} />
                    <label cssClasses={["time"]} halign={Gtk.Align.END}
                        label={time(n)} />
                </box>
                <label cssClasses={["summary"]} halign={Gtk.Align.START}
                    xalign={0} wrap maxWidthChars={30} label={n.summary || ""} />
            </box>
            <button cssClasses={["close"]} valign={Gtk.Align.START}
                onClicked={() => n.dismiss()}>
                <image iconName="window-close-symbolic" pixelSize={14} />
            </button>
        </box>
        {n.body && n.body.length > 0 && <label
            cssClasses={["body"]} halign={Gtk.Align.START} xalign={0}
            wrap maxWidthChars={34} useMarkup label={n.body} />}
        {n.actions.length > 0 && <box cssClasses={["actions"]} spacing={6}
            homogeneous>
            {n.actions.map(a => <button cssClasses={["action"]} hexpand
                onClicked={() => n.invoke(a.id)}>
                <label label={a.label} />
            </button>)}
        </box>}
    </box>
}
