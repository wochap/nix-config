# remote-desktop-vt-keys
#
# Keeps Ctrl+Alt+F1..F12 on this machine while Moonlight streams from a bare
# TTY (--backend eglfs). Moonlight reads evdev itself and forwards every key to
# the host, and SDL mutes the console keyboard, so nothing local switches VT.
# This grabs every keyboard and replays its events through a uinput clone,
# which Moonlight reads instead. On Ctrl+Alt+Fn it drops the F key, releases
# Ctrl and Alt on the host and switches the local VT. Start it on the
# streaming VT before Moonlight; it prints "ready" once the clones exist and
# exits when that VT is no longer active.
#
#   remote-desktop-vt-keys <own vt number>

import fcntl
import os
import select
import sys

import evdev
from evdev import ecodes

VT_ACTIVATE = 0x5606
CLONE_PREFIX = "remote-desktop "

MODIFIERS = {
    "ctrl": {ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL},
    "alt": {ecodes.KEY_LEFTALT, ecodes.KEY_RIGHTALT},
}
FUNCTION_KEYS = {getattr(ecodes, f"KEY_F{n}"): n for n in range(1, 13)}

own_vt = int(sys.argv[1])


def active_vt():
    try:
        with open("/sys/class/tty/tty0/active") as f:
            return int(f.read().strip().removeprefix("tty"))
    except (OSError, ValueError):
        return own_vt


def is_keyboard(device):
    keys = device.capabilities().get(ecodes.EV_KEY, [])
    return ecodes.KEY_A in keys and ecodes.KEY_F1 in keys


def grab_keyboards():
    clones = {}
    for path in evdev.list_devices():
        try:
            device = evdev.InputDevice(path)
        except OSError:
            continue
        if device.name.startswith(CLONE_PREFIX) or not is_keyboard(device):
            device.close()
            continue
        try:
            # fails for devices another tool already grabs, e.g. interception
            # tools, whose own uinput output is grabbed instead
            device.grab()
        except OSError:
            device.close()
            continue
        clones[device.fd] = (device, evdev.UInput.from_device(device, name=CLONE_PREFIX + device.name))
    return clones


def release_modifiers(clone, held):
    for code in held & (MODIFIERS["ctrl"] | MODIFIERS["alt"]):
        clone.write(ecodes.EV_KEY, code, 0)
    clone.syn()


def main():
    clones = grab_keyboards()
    held = set()
    print("ready", flush=True)

    while active_vt() == own_vt:
        readable, _, _ = select.select(list(clones), [], [], 0.5)
        for fd in readable:
            device, clone = clones[fd]
            try:
                events = list(device.read())
            except OSError:
                # unplugged
                del clones[fd]
                clone.close()
                continue
            for event in events:
                if event.type == ecodes.EV_KEY:
                    if event.value == 0:
                        held.discard(event.code)
                    else:
                        held.add(event.code)

                    vt = FUNCTION_KEYS.get(event.code)
                    combo = held & MODIFIERS["ctrl"] and held & MODIFIERS["alt"]
                    if vt is not None and combo:
                        if event.value == 1 and vt != own_vt:
                            release_modifiers(clone, held)
                            tty = os.open("/dev/tty", os.O_RDWR)
                            fcntl.ioctl(tty, VT_ACTIVATE, vt)
                            # exit closes the clones and drops the grabs
                            return
                        continue
                clone.write_event(event)


main()
