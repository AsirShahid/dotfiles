// Safe accessors for the Astal service singletons. Each get_default() is
// wrapped so a missing library/device degrades to null instead of taking
// the whole shell down; widgets null-check before binding.

import AstalBattery from "gi://AstalBattery"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth"
import AstalWp from "gi://AstalWp"
import AstalMpris from "gi://AstalMpris"
import AstalNotifd from "gi://AstalNotifd"
import AstalPowerProfiles from "gi://AstalPowerProfiles"

function safe<T>(fn: () => T): T | null {
    try {
        return fn()
    } catch (err) {
        console.error("service unavailable:", err)
        return null
    }
}

export const battery = safe(() => AstalBattery.get_default())
export const network = safe(() => AstalNetwork.get_default())
export const bluetooth = safe(() => AstalBluetooth.get_default())
export const mpris = safe(() => AstalMpris.get_default())
export const notifd = safe(() => AstalNotifd.get_default())
export const powerprofiles = safe(() => AstalPowerProfiles.get_default())

// Default output endpoint (speaker); guarded because a machine may boot
// with no sink, and because `.audio` vs a flat accessor has moved between
// AstalWp releases.
const wp = safe(() => AstalWp.get_default())
const audio = (wp?.audio ?? wp) as AstalWp.Audio | null
export const speaker = audio?.defaultSpeaker ?? null
export const microphone = audio?.defaultMicrophone ?? null

export { AstalNotifd }
