// Noctalia-inspired top bar. One quiet surface with app context on the left,
// workspaces in the visual center, and status controls on the right.

import { App, Astal, Gtk, Gdk } from "astal/gtk4"
import { Variable, bind } from "astal"
import GLib from "gi://GLib"
import Pango from "gi://Pango"
import AstalTray from "gi://AstalTray"
import { workspaces, focusedTitle, focusWorkspace } from "../lib/niri"
import { battery, network, bluetooth, speaker } from "../lib/services"
import { qsVisible } from "./QuickSettings"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

const clock = Variable(GLib.DateTime.new_now_local()).poll(
    10_000, () => GLib.DateTime.new_now_local())

function Launcher() {
    return <button
        cssClasses={["launcher"]}
        tooltipText="Apps  (Super+D)"
        onClicked={() => GLib.spawn_command_line_async(
            "fuzzel --config /var/home/ashahid/.config/fuzzel/niri.ini")}>
        <image iconName="view-app-grid-symbolic" pixelSize={17} />
    </button>
}

function Workspaces() {
    return <box cssClasses={["workspaces"]} spacing={4}>
        {bind(workspaces).as(list => list.map(ws => (
            <button
                cssClasses={
                    ws.is_focused ? ["ws", "focused"]
                        : ws.is_active ? ["ws", "active"]
                            : ["ws"]}
                onClicked={() => focusWorkspace(ws.idx)}>
                <label label={ws.name && ws.name.length > 0
                    ? ws.name : String(ws.idx)} />
            </button>
        )))}
    </box>
}

function Title() {
    return <label
        cssClasses={["title"]}
        maxWidthChars={36}
        ellipsize={Pango.EllipsizeMode.END}
        visible={bind(focusedTitle).as(t => t.length > 0)}
        label={bind(focusedTitle)} />
}

function Clock() {
    return <button cssClasses={["clock"]}
        tooltipText={bind(clock).as(t => t.format("%A, %B %d, %Y") ?? "")}
        onClicked={() => (qsVisible.set(!qsVisible.get()))}>
        <label label={bind(clock).as(t => {
            const hour = t.get_hour() % 12 || 12
            const minute = String(t.get_minute()).padStart(2, "0")
            const meridiem = t.get_hour() < 12 ? "AM" : "PM"
            const day = t.format("%a") ?? ""
            return `${day} ${t.get_day_of_month()}  ·  ${hour}:${minute} ${meridiem}`
        })} />
    </button>
}

function Tray() {
    const tray = AstalTray.get_default()
    return <box cssClasses={["tray"]} spacing={2}>
        {bind(tray, "items").as(items => items.map(item => (
            <menubutton cssClasses={["tray-item"]}
                tooltipText={bind(item, "tooltipMarkup")}
                setup={self => {
                    self.menuModel = item.menuModel
                    self.insert_action_group("dbusmenu", item.actionGroup)
                    item.connect("notify::action-group", () =>
                        self.insert_action_group("dbusmenu", item.actionGroup))
                }}>
                <image gicon={bind(item, "gicon")} pixelSize={16} />
            </menubutton>
        )))}
    </box>
}

// Compact cluster of status icons; the whole cluster toggles Quick Settings.
function StatusPill() {
    const net = network
    const netIcon =
        net?.wifi ? bind(net.wifi, "iconName")
            : net?.wired ? bind(net.wired, "iconName")
                : "network-wireless-offline-symbolic"

    return <button
        cssClasses={["pill"]}
        tooltipText="Quick settings"
        onClicked={() => qsVisible.set(!qsVisible.get())}>
        <box spacing={9}>
            <image iconName={netIcon} pixelSize={16} />
            {bluetooth && <image
                iconName={bind(bluetooth, "isPowered").as(p =>
                    p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic")}
                visible={bind(bluetooth, "isPowered")} />}
            {speaker && <image iconName={bind(speaker, "volumeIcon")} pixelSize={16} />}
            {battery?.isPresent && <box spacing={5}
                cssClasses={bind(battery, "percentage").as(p =>
                    p <= 0.15 ? ["battery", "critical"] : ["battery"])}>
                <image iconName={bind(battery, "batteryIconName")} pixelSize={16} />
                <label label={bind(battery, "percentage").as(p =>
                    `${Math.round(p * 100)}%`)} />
            </box>}
        </box>
    </button>
}

function Power() {
    return <button cssClasses={["power"]}
        tooltipText="Power  (Super+Backspace)"
        onClicked={() => GLib.spawn_command_line_async(
            "/var/home/ashahid/.local/bin/niri-power-menu")}>
        <image iconName="system-shutdown-symbolic" pixelSize={16} />
    </button>
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
    return <window
        cssClasses={["bar"]}
        namespace="niri-bar"
        gdkmonitor={gdkmonitor}
        anchor={TOP | LEFT | RIGHT}
        marginTop={8}
        marginLeft={12}
        marginRight={12}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        visible
        application={App}>
        <centerbox cssClasses={["bar-surface"]}>
            {/* CenterBox children are positional: start, center, end. */}
            <box cssClasses={["bar-start"]} spacing={8}>
                <Launcher />
                <Title />
            </box>
            <box cssClasses={["bar-center"]} halign={Gtk.Align.CENTER}>
                <Workspaces />
            </box>
            <box cssClasses={["bar-end"]} spacing={6} halign={Gtk.Align.END}>
                <Tray />
                <StatusPill />
                <Clock />
                <Power />
            </box>
        </centerbox>
    </window>
}
