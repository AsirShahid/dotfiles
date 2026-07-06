// Floating top bar. Left: launcher + niri workspaces + focused title.
// Center: clock. Right: system tray + a status pill (net/bt/vol/battery)
// that toggles Quick Settings, + a power button.

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
        <label label="" />
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
        maxWidthChars={48}
        ellipsize={Pango.EllipsizeMode.END}
        visible={bind(focusedTitle).as(t => t.length > 0)}
        label={bind(focusedTitle)} />
}

function Clock() {
    return <button cssClasses={["clock"]}
        onClicked={() => (qsVisible.set(!qsVisible.get()))}>
        <label label={bind(clock).as(t => t.format("%a %b %-e   %-I:%M %p") ?? "")} />
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

// Compact cluster of status icons; whole thing toggles Quick Settings.
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
            {battery?.isPresent && <box spacing={5}>
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
        <label label="" />
    </button>
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
    return <window
        cssClasses={["bar"]}
        namespace="niri-bar"
        gdkmonitor={gdkmonitor}
        anchor={TOP | LEFT | RIGHT}
        marginTop={6}
        marginLeft={10}
        marginRight={10}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        application={App}>
        <centerbox cssClasses={["bar-inner"]}>
            {/* CenterBox children are positional: start, center, end. */}
            <box spacing={8}>
                <Launcher />
                <Workspaces />
                <Title />
            </box>
            <box>
                <Clock />
            </box>
            <box spacing={8} halign={Gtk.Align.END}>
                <Tray />
                <StatusPill />
                <Power />
            </box>
        </centerbox>
    </window>
}
