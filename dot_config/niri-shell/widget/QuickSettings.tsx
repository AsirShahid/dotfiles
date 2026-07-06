// Quick Settings — a top-right panel toggled from the bar (qsVisible).
// Header, toggle grid, volume/brightness sliders, media card, and the
// recent-notification list.

import { App, Astal, Gtk } from "astal/gtk4"
import { Variable, bind } from "astal"
import GLib from "gi://GLib"
import { brightness, setBrightness } from "../lib/brightness"
import {
    battery, network, bluetooth, speaker, mpris, notifd, powerprofiles,
} from "../lib/services"
import NotificationCard from "./Notification"

const { TOP, RIGHT } = Astal.WindowAnchor

// Shared open/closed state; the bar flips this.
export const qsVisible = Variable(false)

function spawn(cmd: string) {
    GLib.spawn_command_line_async(cmd)
}

function Header() {
    const user = GLib.get_user_name()
    return <box cssClasses={["qs-header"]} spacing={10}>
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
            <label cssClasses={["greeting"]} halign={Gtk.Align.START}
                label={`Hi, ${user}`} />
            {battery?.isPresent && <label cssClasses={["subtle"]}
                halign={Gtk.Align.START}
                label={bind(battery, "percentage").as(p =>
                    `Battery ${Math.round(p * 100)}%`)} />}
        </box>
        <button cssClasses={["hbtn"]} tooltipText="Settings"
            onClicked={() => { spawn("gnome-control-center"); qsVisible.set(false) }}>
            <label label="" />
        </button>
        <button cssClasses={["hbtn"]} tooltipText="Lock"
            onClicked={() => { spawn("/var/home/ashahid/.local/bin/niri-lock"); qsVisible.set(false) }}>
            <label label="" />
        </button>
        <button cssClasses={["hbtn", "danger"]} tooltipText="Power"
            onClicked={() => { spawn("/var/home/ashahid/.local/bin/niri-power-menu"); qsVisible.set(false) }}>
            <label label="" />
        </button>
    </box>
}

function Toggle(p: {
    icon: string
    label: string
    active: ReturnType<typeof bind>
    onClicked: () => void
    onRightClick?: () => void
}) {
    return <button
        cssClasses={p.active.as((on: boolean) =>
            on ? ["qs-toggle", "on"] : ["qs-toggle"])}
        onClicked={p.onClicked}
        onButtonPressed={(_, event) => {
            if (p.onRightClick && event.get_button() === 3) p.onRightClick()
        }}>
        <box spacing={10}>
            <image iconName={p.icon} pixelSize={18} />
            <label label={p.label} halign={Gtk.Align.START} hexpand />
        </box>
    </button>
}

function Toggles() {
    const items: Gtk.Widget[] = []

    if (network?.wifi) {
        items.push(Toggle({
            icon: "network-wireless-symbolic",
            label: "Wi-Fi",
            active: bind(network.wifi, "enabled"),
            onClicked: () => spawn(network.wifi.enabled
                ? "nmcli radio wifi off" : "nmcli radio wifi on"),
            onRightClick: () => { spawn("nm-connection-editor"); qsVisible.set(false) },
        }))
    }

    if (bluetooth) {
        items.push(Toggle({
            icon: "bluetooth-symbolic",
            label: "Bluetooth",
            active: bind(bluetooth, "isPowered"),
            onClicked: () => {
                const a = bluetooth.adapter
                if (a) a.powered = !a.powered
            },
            onRightClick: () => { spawn("blueman-manager"); qsVisible.set(false) },
        }))
    }

    if (notifd) {
        items.push(Toggle({
            icon: "notifications-disabled-symbolic",
            label: "Do Not Disturb",
            active: bind(notifd, "dontDisturb"),
            onClicked: () => { notifd.dontDisturb = !notifd.dontDisturb },
        }))
    }

    if (powerprofiles) {
        const order = ["power-saver", "balanced", "performance"]
        const nice: Record<string, string> = {
            "power-saver": "Power Saver", "balanced": "Balanced",
            "performance": "Performance",
        }
        items.push(Toggle({
            icon: "power-profile-balanced-symbolic",
            label: bind(powerprofiles, "activeProfile").as(p =>
                nice[p] ?? p) as unknown as string,
            active: bind(powerprofiles, "activeProfile").as(p => p === "performance"),
            onClicked: () => {
                const cur = order.indexOf(powerprofiles.activeProfile)
                powerprofiles.activeProfile = order[(cur + 1) % order.length]
            },
        }))
    }

    return <box cssClasses={["qs-toggles"]}
        orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        {items}
    </box>
}

function Sliders() {
    return <box cssClasses={["qs-sliders"]}
        orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        {speaker && <box spacing={10}>
            <image iconName={bind(speaker, "volumeIcon")} pixelSize={18} />
            <slider cssClasses={["slider"]} hexpand
                min={0} max={1} step={0.01}
                value={bind(speaker, "volume")}
                onChangeValue={self => { speaker.volume = self.value }} />
        </box>}
        <box spacing={10}>
            <image iconName="display-brightness-symbolic" pixelSize={18} />
            <slider cssClasses={["slider"]} hexpand
                min={0.01} max={1} step={0.01}
                value={bind(brightness)}
                onChangeValue={self => setBrightness(self.value)} />
        </box>
    </box>
}

function Media() {
    if (!mpris) return <box visible={false} />
    return <box visible={bind(mpris, "players").as(p => p.length > 0)}>
        {bind(mpris, "players").as(players => {
            const p = players[0]
            if (!p) return <box visible={false} />
            return <box cssClasses={["media"]} spacing={12}>
                <image cssClasses={["cover"]} pixelSize={56}
                    iconName="emblem-music-symbolic"
                    file={bind(p, "coverArt")} />
                <box orientation={Gtk.Orientation.VERTICAL} hexpand
                    valign={Gtk.Align.CENTER}>
                    <label cssClasses={["media-title"]} halign={Gtk.Align.START}
                        xalign={0} maxWidthChars={22} ellipsize={3}
                        label={bind(p, "title").as(t => t || "Unknown")} />
                    <label cssClasses={["media-artist"]} halign={Gtk.Align.START}
                        xalign={0} maxWidthChars={22} ellipsize={3}
                        label={bind(p, "artist").as(a => a || "")} />
                </box>
                <box valign={Gtk.Align.CENTER} spacing={2}>
                    <button cssClasses={["media-btn"]} onClicked={() => p.previous()}>
                        <label label="" />
                    </button>
                    <button cssClasses={["media-btn"]} onClicked={() => p.play_pause()}>
                        <label label={bind(p, "playbackStatus").as(s =>
                            s === 0 /* PLAYING */ ? "" : "")} />
                    </button>
                    <button cssClasses={["media-btn"]} onClicked={() => p.next()}>
                        <label label="" />
                    </button>
                </box>
            </box>
        })}
    </box>
}

function NotificationList() {
    if (!notifd) return <box visible={false} />
    return <box cssClasses={["qs-notifications"]}
        orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <box cssClasses={["qs-section"]}>
            <label cssClasses={["section-title"]} halign={Gtk.Align.START}
                hexpand label="Notifications" />
            <button cssClasses={["clear"]}
                onClicked={() => notifd.notifications.forEach(n => n.dismiss())}>
                <label label="  Clear" />
            </button>
        </box>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            {bind(notifd, "notifications").as(list => list.length === 0
                ? [<label cssClasses={["empty"]} label="No notifications" />]
                : list.slice(-6).reverse().map(n => NotificationCard(n)))}
        </box>
    </box>
}

export default function QuickSettings() {
    return <window
        cssClasses={["qs-window"]}
        namespace="niri-quicksettings"
        anchor={TOP | RIGHT}
        marginTop={6}
        marginRight={10}
        layer={Astal.Layer.OVERLAY}
        keymode={Astal.Keymode.ON_DEMAND}
        visible={bind(qsVisible)}
        application={App}
        onKeyPressed={(_, keyval) => {
            if (keyval === 65307 /* Escape */) qsVisible.set(false)
        }}>
        <box cssClasses={["qs"]} orientation={Gtk.Orientation.VERTICAL}
            spacing={14} widthRequest={360}>
            <Header />
            <Sliders />
            <Toggles />
            <Media />
            <NotificationList />
        </box>
    </window>
}
