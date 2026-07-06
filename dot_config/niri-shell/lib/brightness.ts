// Backlight as a reactive Variable, via brightnessctl (no Astal lib for
// this). Polled slowly to pick up changes made by the hardware keys
// (which go through ~/.local/bin/niri-osd).

import { Variable, exec, execAsync } from "astal"

function read(): number {
    try {
        const max = Number(exec("brightnessctl max")) || 1
        return Number(exec("brightnessctl get")) / max
    } catch {
        return 1
    }
}

export const brightness: Variable<number> = Variable(read())
brightness.poll(5000, read)

export function setBrightness(value: number) {
    const clamped = Math.max(0.01, Math.min(1, value))
    brightness.set(clamped)
    execAsync(["brightnessctl", "-q", "set", `${Math.round(clamped * 100)}%`])
        .catch(err => console.error("brightnessctl:", err))
}
