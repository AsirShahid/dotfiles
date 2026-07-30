// Quick Settings — a top-right panel toggled from the bar (qsVisible).
// Header, toggle grid, volume/brightness sliders, media card, and the
// recent-notification list.

import { App, Astal, Gtk } from "astal/gtk4"
import { Variable, bind, derive, type Binding } from "astal"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import { brightness, setBrightness } from "../lib/brightness"
import {
    battery, network, bluetooth, speaker, mpris, notifd, powerprofiles,
} from "../lib/services"
import NotificationCard from "./Notification"

const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor

// Shared open/closed state; the bar flips this.
export const qsVisible = Variable(false)

// Force the panel closed when the session locks or the machine suspends.
// The window below is a full-output OVERLAY layer (its transparent
// dismiss button spans the screen), so one that survives a lock sits
// above everything after unlock and eats all input. Watch logind on the
// system bus: Manager.PrepareForSleep for suspend, Session.Lock for
// `loginctl lock-session` (hypridle's idle path), and the LockedHint
// property for lockers started directly (hyprlock/swaylock set it).
try {
    const bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, null)
    const close = () => qsVisible.set(false)
    bus.signal_subscribe(
        "org.freedesktop.login1", "org.freedesktop.login1.Manager",
        "PrepareForSleep", "/org/freedesktop/login1", null,
        Gio.DBusSignalFlags.NONE, close)
    // Object path left null: single-seat machine, any session's Lock counts.
    bus.signal_subscribe(
        "org.freedesktop.login1", "org.freedesktop.login1.Session",
        "Lock", null, null,
        Gio.DBusSignalFlags.NONE, close)
    bus.signal_subscribe(
        "org.freedesktop.login1", "org.freedesktop.DBus.Properties",
        "PropertiesChanged", null, "org.freedesktop.login1.Session",
        Gio.DBusSignalFlags.NONE,
        (_bus, _sender, _path, _iface, _signal, params) => {
            // (interface, changed a{sv}, invalidated); deepUnpack keeps
            // the dict values as Variants.
            const changed = params.get_child_value(1)
                .deepUnpack() as Record<string, GLib.Variant>
            if (changed["LockedHint"]?.get_boolean()) close()
        })
} catch (err) {
    console.error("login1 subscription failed:", err)
}

function spawn(cmd: string) {
    GLib.spawn_command_line_async(cmd)
}

type Reactive<T> = T | Binding<T>

function Header() {
    const user = GLib.get_user_name()
    return <box cssClasses={["qs-header"]} spacing={10}>
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
            <label cssClasses={["greeting"]} halign={Gtk.Align.START}
                label="Quick settings" />
            <label cssClasses={["subtle"]} halign={Gtk.Align.START}
                label={battery?.isPresent
                    ? bind(battery, "percentage").as(p =>
                        `${user}  ·  Battery ${Math.round(p * 100)}%`)
                    : user} />
        </box>
        <button cssClasses={["hbtn"]} tooltipText="Settings"
            onClicked={() => { spawn("gnome-control-center"); qsVisible.set(false) }}>
            <image iconName="emblem-system-symbolic" pixelSize={16} />
        </button>
        <button cssClasses={["hbtn"]} tooltipText="Lock"
            onClicked={() => { spawn("/var/home/ashahid/.local/bin/niri-lock"); qsVisible.set(false) }}>
            <image iconName="system-lock-screen-symbolic" pixelSize={16} />
        </button>
        <button cssClasses={["hbtn", "danger"]} tooltipText="Power"
            onClicked={() => { spawn("/var/home/ashahid/.local/bin/niri-power-menu"); qsVisible.set(false) }}>
            <image iconName="system-shutdown-symbolic" pixelSize={16} />
        </button>
    </box>
}

function Toggle(p: {
    icon: Reactive<string>
    label: Reactive<string>
    status?: Reactive<string>
    active: Binding<boolean>
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
        <box cssClasses={["toggle-content"]} spacing={10}>
            <box cssClasses={["toggle-icon"]}>
                <image iconName={p.icon} pixelSize={17} />
            </box>
            <box cssClasses={["toggle-copy"]}
                orientation={Gtk.Orientation.VERTICAL}
                valign={Gtk.Align.CENTER} hexpand>
                <label cssClasses={["toggle-label"]}
                    label={p.label} halign={Gtk.Align.START}
                    xalign={0} maxWidthChars={17} ellipsize={3} />
                {p.status !== undefined && <label
                    cssClasses={["toggle-status"]}
                    label={p.status} halign={Gtk.Align.START}
                    xalign={0} maxWidthChars={17} ellipsize={3} />}
            </box>
        </box>
    </button>
}

function Toggles() {
    const items: Gtk.Widget[] = []

    if (network?.wifi) {
        const wifi = network.wifi
        const wifiEnabled = bind(wifi, "enabled")
        const wifiStatus = derive(
            [wifiEnabled, bind(wifi, "ssid")],
            (enabled, ssid) => {
                const name = ssid?.trim()
                if (!enabled) return "Off"
                return name || "Not connected"
            },
        )

        items.push(Toggle({
            icon: bind(wifi, "iconName"),
            label: "Wi-Fi",
            status: wifiStatus(),
            active: wifiEnabled,
            onClicked: () => spawn(wifi.enabled
                ? "nmcli radio wifi off" : "nmcli radio wifi on"),
            onRightClick: () => { spawn("nm-connection-editor"); qsVisible.set(false) },
        }))
    }

    if (bluetooth) {
        const bluetoothPowered = bind(bluetooth, "isPowered")
        const bluetoothConnected = bind(bluetooth, "isConnected")
        const bluetoothStatus = derive(
            [
                bluetoothPowered,
                bluetoothConnected,
                bind(bluetooth, "devices"),
            ],
            (powered, connected, devices) => {
                if (!powered) return "Off"
                if (!connected) return "Not connected"

                const names = devices
                    .filter(device => device.connected)
                    .map(device => (device.alias || device.name || "").trim())
                    .filter(Boolean)

                if (names.length === 0) return "Connected"
                return names.length === 1
                    ? names[0]
                    : `${names[0]} +${names.length - 1}`
            },
        )
        const bluetoothIcon = derive(
            [bluetoothPowered, bluetoothConnected],
            (powered, connected) => !powered
                ? "bluetooth-disabled-symbolic"
                : connected
                    ? "bluetooth-active-symbolic"
                    : "bluetooth-disconnected-symbolic",
        )

        items.push(Toggle({
            icon: bluetoothIcon(),
            label: "Bluetooth",
            status: bluetoothStatus(),
            active: bluetoothPowered,
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
                nice[p] ?? p),
            active: bind(powerprofiles, "activeProfile").as(p => p === "performance"),
            onClicked: () => {
                const cur = order.indexOf(powerprofiles.activeProfile)
                powerprofiles.activeProfile = order[(cur + 1) % order.length]
            },
        }))
    }

    const rows: Gtk.Widget[] = []
    for (let i = 0; i < items.length; i += 2) {
        rows.push(<box homogeneous spacing={8}>{items.slice(i, i + 2)}</box>)
    }

    return <box cssClasses={["qs-toggles"]}
        orientation={Gtk.Orientation.VERTICAL} spacing={8}>{rows}</box>
}

function Sliders() {
    return <box cssClasses={["qs-sliders"]}
        orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        {speaker && <box cssClasses={["slider-row"]} spacing={10}>
            <image iconName={bind(speaker, "volumeIcon")} pixelSize={18} />
            <slider cssClasses={["slider"]} hexpand
                min={0} max={1} step={0.01}
                value={bind(speaker, "volume")}
                onChangeValue={self => { speaker.volume = self.value }} />
        </box>}
        <box cssClasses={["slider-row"]} spacing={10}>
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
                        <image iconName="media-skip-backward-symbolic" pixelSize={17} />
                    </button>
                    <button cssClasses={["media-btn"]} onClicked={() => p.play_pause()}>
                        <image pixelSize={18}
                            iconName={bind(p, "playbackStatus").as(s =>
                                s === 0 /* PLAYING */
                                    ? "media-playback-pause-symbolic"
                                    : "media-playback-start-symbolic")} />
                    </button>
                    <button cssClasses={["media-btn"]} onClicked={() => p.next()}>
                        <image iconName="media-skip-forward-symbolic" pixelSize={17} />
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
        anchor={TOP | RIGHT | BOTTOM | LEFT}
        layer={Astal.Layer.OVERLAY}
        keymode={Astal.Keymode.ON_DEMAND}
        visible={bind(qsVisible)}
        application={App}
        onKeyPressed={(_, keyval) => {
            if (keyval === 65307 /* Escape */) qsVisible.set(false)
        }}>
        <overlay>
            {/* Full-window hit target gives this detached layer-window the
                same click-away behavior as a native Gtk.Popover. */}
            <button cssClasses={["qs-dismiss"]} hexpand vexpand
                onClicked={() => qsVisible.set(false)} />
            <box type="overlay" cssClasses={["qs"]}
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.END} valign={Gtk.Align.START}
                marginTop={8} marginEnd={12}
                spacing={12} widthRequest={380}>
                <Header />
                <Sliders />
                <Toggles />
                <Media />
                <NotificationList />
            </box>
        </overlay>
    </window>
}
