from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut


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


# Copy the kitty selection to the clipboard if there is one,
# otherwise send `key_mapping` to the program (zsh, nvim, tmux, ...)
# so it can copy its own selection
@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    key_mapping = args[1]

    if window is None:
        return
    if window.has_selection():
        window.copy_to_clipboard()
        window.clear_selection()
    else:
        window.write_to_child(encode_key_mapping(window, key_mapping))
