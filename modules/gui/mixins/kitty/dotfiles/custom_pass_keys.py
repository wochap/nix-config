import re

from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut


def is_window_tui(window, tui_id):
    from kittens.tui.loop import debug

    debug(tui_id)
    fp = window.child.foreground_processes
    return any(
        re.search(tui_id, p["cmdline"][0] if len(p["cmdline"]) else "", re.I)
        for p in fp
    )


def encode_key_mapping(window, key_mapping):
    mods, key = parse_shortcut(key_mapping)
    event = KeyEvent(
        mods=mods,
        key=key,
        shift=bool(mods & 1),
        alt=bool(mods & 2),
        ctrl=bool(mods & 4),
        super=bool(mods & 8),
        hyper=bool(mods & 16),
        meta=bool(mods & 32),
    ).as_window_system_event()

    return window.encoded_key(event)


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    key_mapping = args[1]
    action = args[2]
    tui_id = "(n?vim|neomutt)"

    if window is None:
        return
    if is_window_tui(window, tui_id):
        for keymap in key_mapping.split(">"):
            encoded = encode_key_mapping(window, keymap)
            window.write_to_child(encoded)
    else:
        action_args = args[2:-1]
        getattr(boss.active_tab, action)(*action_args)
