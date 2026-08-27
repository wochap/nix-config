# source: https://github.com/kovidgoyal/kitty/blob/master/kitty/tab_bar.py

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    color_as_int,
    draw_tab_with_separator,
)

opts = get_options()

active_tab_background = as_rgb(color_as_int(opts.active_tab_background))
inactive_tab_foreground = as_rgb(color_as_int(opts.inactive_tab_foreground))
tab_bar_background = as_rgb(color_as_int(opts.tab_bar_background))
windows_icon = ""
folder_icon = "󰉖"
default_layout_icon = ""
layout_icon_by_name = {
    "fat": "",
    "tall": "",
    "stack": "",
    "splits": "",
}
active_tab_layout_name = ""
active_tab_num_windows = 1
left_indicator = ""
right_indicator = ""

_layout_tab_widths: list[int] = []
_active_tab_idx = 0
_viewport_start = 0
_viewport_end = 0
_num_tabs = 0
_right_space = 0
_tabs_draw_x = 0


def draw_title(data: dict) -> str:
    """Prefer an application's title, falling back to the cwd at a shell prompt."""
    tab = data["tab"]
    cwd = tab.active_wd.rsplit("/", 1)[-1]
    shells = {"bash", "dash", "fish", "nu", "sh", "zsh"}
    title = data["title"] if tab.active_exe not in shells else cwd
    title = title or cwd or data["title"]
    if len(title) <= 30:
        return title
    return title[:15] + "…" + title[-14:]


def _calculate_viewport(available_width: int) -> None:
    global _viewport_start, _viewport_end

    num_tabs = len(_layout_tab_widths)
    if num_tabs == 0:
        _viewport_start = 0
        _viewport_end = 0
        return

    width = max(1, available_width - 4)
    active = _active_tab_idx

    start = active
    end = active + 1
    used = min(_layout_tab_widths[active], width)

    # Active never adjacent to indicators: seed 1 neighbor each side
    if start > 0 and used + _layout_tab_widths[start - 1] <= width:
        start -= 1
        used += _layout_tab_widths[start]
    if end < num_tabs and used + _layout_tab_widths[end] <= width:
        used += _layout_tab_widths[end]
        end += 1

    # Expand preferring side with fewer tabs (keeps active centered)
    while True:
        expanded = False
        if (active - start) <= (end - active - 1):
            if start > 0 and used + _layout_tab_widths[start - 1] <= width:
                start -= 1
                used += _layout_tab_widths[start]
                expanded = True
            elif end < num_tabs and used + _layout_tab_widths[end] <= width:
                used += _layout_tab_widths[end]
                end += 1
                expanded = True
        else:
            if end < num_tabs and used + _layout_tab_widths[end] <= width:
                used += _layout_tab_widths[end]
                end += 1
                expanded = True
            elif start > 0 and used + _layout_tab_widths[start - 1] <= width:
                start -= 1
                used += _layout_tab_widths[start]
                expanded = True
        if not expanded:
            break

    _viewport_start = start
    _viewport_end = end


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global active_tab_layout_name
    global active_tab_num_windows
    global active_tab_background
    global inactive_tab_foreground
    global tab_bar_background
    global _layout_tab_widths
    global _active_tab_idx
    global _viewport_start
    global _viewport_end
    global _num_tabs
    global _right_space
    global _tabs_draw_x

    if tab.is_active:
        active_tab_layout_name = tab.layout_name
        active_tab_num_windows = tab.num_windows

    # --- Layout pass: measure ideal tab widths ---
    if extra_data.for_layout:
        if index == 1:
            _layout_tab_widths = []
            _active_tab_idx = 0
        if tab.is_active:
            _active_tab_idx = index - 1
        draw_tab_with_separator(
            draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
        )
        _layout_tab_widths.append(max(1, screen.cursor.x))
        return screen.cursor.x

    # --- Real drawing pass ---
    # Colors: compute once per frame (draw_data constant across tabs)
    if index == 1:
        active_tab_background = as_rgb(color_as_int(draw_data.active_bg))
        inactive_tab_foreground = as_rgb(color_as_int(draw_data.inactive_fg))
        tab_bar_background = as_rgb(color_as_int(draw_data.default_bg))

    tab_idx = index - 1

    # Default cursor for padding/status/indicators (prevents active
    # tab bg bleeding into leading spaces)
    screen.cursor.fg = inactive_tab_foreground
    screen.cursor.bg = tab_bar_background

    if index == 1:
        _num_tabs = len(_layout_tab_widths)
        total_ideal = sum(_layout_tab_widths)

        if total_ideal <= screen.columns:
            _viewport_start = 0
            _viewport_end = _num_tabs
            content_start = (screen.columns - total_ideal) // 2
            content_end = content_start + total_ideal
            has_left_indicator = False
            has_right_indicator = False
        else:
            _calculate_viewport(screen.columns)
            viewport_total = sum(_layout_tab_widths[_viewport_start:_viewport_end])
            has_left_indicator = _viewport_start > 0
            has_right_indicator = _viewport_end < _num_tabs
            indicator_w = (2 if has_left_indicator else 0) + (
                2 if has_right_indicator else 0
            )
            content_start = max(0, (screen.columns - viewport_total - indicator_w) // 2)
            content_end = content_start + indicator_w + viewport_total

        left_space = content_start - 1
        if left_space > 0:
            _draw_left_status(screen, left_space)

        if screen.cursor.x < content_start:
            screen.draw(" " * (content_start - screen.cursor.x))

        if has_left_indicator:
            screen.draw(left_indicator + " ")

        _tabs_draw_x = screen.cursor.x
        _right_space = max(0, screen.columns - content_end - 1)

    # Non-visible tabs: inverted extent, never matches clicks
    if tab_idx < _viewport_start or tab_idx >= _viewport_end:
        screen.cursor.x = 0
        return -1

    if tab_idx == _viewport_start and screen.cursor.x < _tabs_draw_x:
        screen.cursor.x = _tabs_draw_x

    draw_tab_with_separator(
        draw_data, screen, tab, before, screen.columns, index, is_last, extra_data
    )
    tab_end = screen.cursor.x

    if tab_idx == _viewport_end - 1:
        if _viewport_end < _num_tabs:
            screen.cursor.fg = inactive_tab_foreground
            screen.cursor.bg = tab_bar_background
            screen.draw(" " + right_indicator)
        if _right_space > 0:
            _draw_right_status(screen, _right_space)

    return tab_end


def _draw_left_status(screen: Screen, max_width: int):
    cwd = _get_parent_cwd()
    if len(cwd) > max_width:
        cwd = cwd[:max_width]
    screen.cursor.fg = inactive_tab_foreground
    screen.cursor.bg = tab_bar_background
    screen.draw(cwd)


def _draw_right_status(screen: Screen, max_width: int):
    keyboard_mode = get_boss().mappings.current_keyboard_mode_name
    layout_fg = (
        inactive_tab_foreground
        if active_tab_layout_name == "fat"
        else active_tab_background
    )
    layout_icon = layout_icon_by_name.get(active_tab_layout_name) or default_layout_icon
    cells = []
    if keyboard_mode and not keyboard_mode.startswith("__"):
        cells.append((active_tab_background, f" {keyboard_mode} "))
    cells.extend([
        (layout_fg, " " + layout_icon + " "),
        (layout_fg, active_tab_layout_name + " "),
        (inactive_tab_foreground, " " + windows_icon + " "),
        (inactive_tab_foreground, str(active_tab_num_windows)),
    ])

    total_width = sum(len(c) for _, c in cells)

    if total_width <= max_width:
        leading = max_width - total_width
        if leading > 0:
            screen.draw(" " * leading)
        for fg, cell in cells:
            screen.cursor.fg = fg
            screen.cursor.bg = tab_bar_background
            screen.draw(cell)
    else:
        full_str = "".join(c for _, c in cells)
        screen.cursor.fg = inactive_tab_foreground
        screen.cursor.bg = tab_bar_background
        screen.draw(full_str[-max_width:])


def _truncate_seg(s: str, max_len: int = 10) -> str:
    if len(s) <= max_len:
        return s
    half = max_len // 2
    return s[:half] + "…" + s[-half:]


def _get_parent_cwd() -> str:
    """Active tab cwd without basename (parent directory), formatted."""
    cwd = ""
    tm = get_boss().active_tab_manager
    if tm is not None:
        w = tm.active_window
        if w is not None:
            cwd = w.cwd_of_child

    parent = cwd.rsplit("/", 1)[0] or "/"
    parts = [p for p in parent.split("/") if p]

    if not parts:
        return folder_icon + " /"

    if parts[0] == "home" and len(parts) > 1:
        parts = ["~"] + parts[2:]
    else:
        parts[0] = "/" + parts[0]

    if len(parts) > 2:
        display = "…/" + "/".join(_truncate_seg(s) for s in parts[-2:])
    else:
        display = "/".join(_truncate_seg(s) for s in parts)

    return folder_icon + " " + display
