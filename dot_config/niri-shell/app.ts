// niri-shell — AGS v2 (aylurs-gtk-shell2) GTK4 desktop shell for the niri
// session. Marble-style: floating bar, quick-settings panel, notification
// popups + OSD. Catppuccin Mocha.
//
// Run:   ags run ~/.config/niri-shell/app.ts   (via ~/.local/bin/niri-shell)
// API:   Astal GTK4 — https://aylur.github.io/astal/
//
// Toolkit note: only GTK4 Astal is packaged for Fedora (astal-gtk4); the
// gtk3 widget lib is not, so this is an `astal/gtk4` project throughout.

import { App } from "astal/gtk4"
import Bar from "./widget/Bar"
import QuickSettings from "./widget/QuickSettings"
import Notifications from "./widget/Notifications"

App.start({
    instanceName: "niri-shell",
    // Astal.apply_css treats a path ending in .css as a file to load.
    css: "/var/home/ashahid/.config/niri-shell/style.css",
    main() {
        App.get_monitors().forEach(Bar)
        Notifications()   // popups + OSD, on the primary monitor
        QuickSettings()   // one panel, toggled from the bar
    },
})
