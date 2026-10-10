# remote-desktop-local-keys
#
# Keeps some keys on this machine while Moonlight streams from a bare TTY.
# Moonlight drops volume keys (it maps no media keys to the host), so this
# turns them into wpctl calls for the local default sink, which plays the
# stream's audio.
#
# --grab (--backend eglfs): Moonlight reads evdev itself and forwards every
# key to the host, and SDL mutes the console keyboard, so nothing local
# switches VT either. This grabs every keyboard and replays its events through
# a uinput clone, which Moonlight reads instead. Volume keys stay here. On
# Ctrl+Alt+Fn it drops the F key, releases Ctrl and Alt on the host and
# switches the local VT.
#
# Without --grab (cage, which switches VT itself) it only reads the keyboards
# alongside cage.
#
# Start it on the streaming VT before Moonlight; it prints "ready" once the
# devices are open and exits when that VT is no longer active.
#
#   remote-desktop-local-keys <own vt number> [--grab]

import fcntl
import os
import select
import subprocess
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
# key -> (wpctl arguments, act on autorepeat)
VOLUME_KEYS = {
    ecodes.KEY_VOLUMEUP: (["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"], True),
    ecodes.KEY_VOLUMEDOWN: (["set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"], True),
    ecodes.KEY_MUTE: (["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], False),
    ecodes.KEY_MICMUTE: (["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"], False),
}

own_vt = int(sys.argv[1])
grab = "--grab" in sys.argv[2:]


def active_vt():
    try:
        with open("/sys/class/tty/tty0/active") as f:
            return int(f.read().strip().removeprefix("tty"))
    except (OSError, ValueError):
        return own_vt


def is_keyboard(device):
    keys = set(device.capabilities().get(ecodes.EV_KEY, []))
    # volume keys often sit on a separate "Consumer Control" device
    return {ecodes.KEY_A, ecodes.KEY_F1} <= keys or bool(keys & VOLUME_KEYS.keys())


def open_keyboards():
    devices = {}
    for path in evdev.list_devices():
        try:
            device = evdev.InputDevice(path)
        except OSError:
            continue
        if device.name.startswith(CLONE_PREFIX) or not is_keyboard(device):
            device.close()
            continue
        clone = None
        if grab:
            try:
                # fails for devices another tool already grabs, e.g. interception
                # tools, whose own uinput output is grabbed instead
                device.grab()
            except OSError:
                device.close()
                continue
            clone = evdev.UInput.from_device(device, name=CLONE_PREFIX + device.name)
        devices[device.fd] = (device, clone)
    return devices


def release_modifiers(clone, held):
    for code in held & (MODIFIERS["ctrl"] | MODIFIERS["alt"]):
        clone.write(ecodes.EV_KEY, code, 0)
    clone.syn()


def volume(event):
    args, repeats = VOLUME_KEYS[event.code]
    if event.value == 1 or (repeats and event.value == 2):
        subprocess.run(["wpctl", *args], check=False)


def main():
    devices = open_keyboards()
    held = set()
    print("ready", flush=True)

    while active_vt() == own_vt:
        readable, _, _ = select.select(list(devices), [], [], 0.5)
        for fd in readable:
            device, clone = devices[fd]
            try:
                events = list(device.read())
            except OSError:
                # unplugged
                del devices[fd]
                if clone:
                    clone.close()
                continue
            for event in events:
                if event.type == ecodes.EV_KEY:
                    if event.code in VOLUME_KEYS:
                        volume(event)
                        continue

                    if event.value == 0:
                        held.discard(event.code)
                    else:
                        held.add(event.code)

                    vt = FUNCTION_KEYS.get(event.code)
                    combo = held & MODIFIERS["ctrl"] and held & MODIFIERS["alt"]
                    if clone and vt is not None and combo:
                        if event.value == 1 and vt != own_vt:
                            release_modifiers(clone, held)
                            tty = os.open("/dev/tty", os.O_RDWR)
                            fcntl.ioctl(tty, VT_ACTIVATE, vt)
                            # exit closes the clones and drops the grabs
                            return
                        continue
                if clone:
                    clone.write_event(event)


main()
