# source: https://github.com/kovidgoyal/kitty/blob/master/kitty/tab_bar.py

from pathlib import Path
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
left_status_length = 0
left_indicator = "<"
right_indicator = ">"

_layout_tab_widths: list[int] = []
_active_tab_idx = 0
_viewport_start = 0
_viewport_end = 0
_num_tabs = 0
_right_space = 0
_tabs_draw_x = 0


def _calculate_viewport(available_width: int) -> None:
    """Calculate visible tab range, keeping active tab centered."""
    global _viewport_start, _viewport_end

    num_tabs = len(_layout_tab_widths)
    if num_tabs == 0:
        _viewport_start = 0
        _viewport_end = 0
        return

    # Reserve for "< " and " >" separators (2 chars each)
    width = max(1, available_width - 4)
    active = _active_tab_idx

    start = active
    end = active + 1
    used = min(_layout_tab_widths[active], width)

    # Ensure active is never adjacent to indicators:
    # add 1 neighbor on each side first (if they exist and fit)
    if start > 0 and used + _layout_tab_widths[start - 1] <= width:
        start -= 1
        used += _layout_tab_widths[start]
    if end < num_tabs and used + _layout_tab_widths[end] <= width:
        used += _layout_tab_widths[end]
        end += 1

    # Expand alternately, preferring the side with fewer tabs
    # so active stays centered in the viewport
    while True:
        expanded = False
        left_count = active - start
        right_count = end - active - 1

        if left_count <= right_count:
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
    global left_status_length
    global _layout_tab_widths
    global _active_tab_idx
    global _viewport_start
    global _viewport_end
    global _num_tabs
    global _right_space
    global _tabs_draw_x

    active_tab_background = as_rgb(color_as_int(draw_data.active_bg))
    inactive_tab_foreground = as_rgb(color_as_int(draw_data.inactive_fg))
    tab_bar_background = as_rgb(color_as_int(draw_data.default_bg))

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
    tab_idx = index - 1

    # Reset cursor colors so padding/status/indicator spaces use
    # tab_bar_background, not the current tab's bg (fixes color bleed
    # when active tab is first and overlaps left status area).
    screen.cursor.fg = inactive_tab_foreground
    screen.cursor.bg = tab_bar_background

    if index == 1:
        _num_tabs = len(_layout_tab_widths)
        total_ideal = sum(_layout_tab_widths)

        if total_ideal <= screen.columns:
            # All tabs fit — center in full width
            _viewport_start = 0
            _viewport_end = _num_tabs
            content_start = (screen.columns - total_ideal) // 2
            content_end = content_start + total_ideal
            has_left_indicator = False
            has_right_indicator = False
        else:
            # Viewport mode with < > indicators
            _calculate_viewport(screen.columns)
            viewport_total = sum(_layout_tab_widths[_viewport_start:_viewport_end])
            has_left_indicator = _viewport_start > 0
            has_right_indicator = _viewport_end < _num_tabs
            # "< " = 2 chars, " >" = 2 chars
            indicator_w = (2 if has_left_indicator else 0) + (
                2 if has_right_indicator else 0
            )
            content_start = max(0, (screen.columns - viewport_total - indicator_w) // 2)
            content_end = content_start + indicator_w + viewport_total

        # Left status: fill space before content (1 char gap from tabs)
        left_space = content_start - 1
        if left_space > 0:
            _draw_left_status(screen, left_space)

        # Pad cursor to content start
        if screen.cursor.x < content_start:
            screen.draw(" " * (content_start - screen.cursor.x))

        # "< " indicator with separator space
        if has_left_indicator:
            screen.cursor.fg = inactive_tab_foreground
            screen.cursor.bg = tab_bar_background
            screen.draw(left_indicator + " ")
            screen.cursor.fg = 0
            screen.cursor.bg = 0

        # Remember where visible tabs should start drawing
        _tabs_draw_x = screen.cursor.x

        # Space available for right status (1 char gap from tabs)
        _right_space = max(0, screen.columns - content_end - 1)

    # Non-visible tabs: park extent at (before, -1) — inverted range
    # never matches any click position.
    if tab_idx < _viewport_start or tab_idx >= _viewport_end:
        screen.cursor.x = 0
        return -1

    # First visible tab: restore cursor to the correct draw position
    # (non-visible tabs parked it at 0).
    if tab_idx == _viewport_start and screen.cursor.x < _tabs_draw_x:
        screen.cursor.x = _tabs_draw_x

    # Draw tab at full ideal width
    draw_tab_with_separator(
        draw_data, screen, tab, before, screen.columns, index, is_last, extra_data
    )
    tab_end = screen.cursor.x

    # After last visible tab: " >" indicator + right status
    if tab_idx == _viewport_end - 1:
        if _viewport_end < _num_tabs:
            screen.cursor.fg = inactive_tab_foreground
            screen.cursor.bg = tab_bar_background
            screen.draw(" " + right_indicator)
            screen.cursor.fg = 0
            screen.cursor.bg = 0
        if _right_space > 0:
            _draw_right_status(screen, _right_space)

    return tab_end


def _draw_left_status(screen: Screen, max_width: int):
    global left_status_length

    cwd = get_cwd()
    if len(cwd) > max_width:
        cwd = cwd[:max_width]
    left_status_length = len(cwd)

    screen.cursor.fg = inactive_tab_foreground
    screen.cursor.bg = tab_bar_background
    screen.draw(cwd)
    screen.cursor.fg = 0
    screen.cursor.bg = 0


def _draw_right_status(screen: Screen, max_width: int):
    layout_fg = (
        inactive_tab_foreground
        if active_tab_layout_name == "fat"
        else active_tab_background
    )
    layout_icon = layout_icon_by_name.get(active_tab_layout_name) or default_layout_icon
    cells = [
        (layout_fg, tab_bar_background, " " + layout_icon + " "),
        (layout_fg, tab_bar_background, active_tab_layout_name + " "),
        (inactive_tab_foreground, tab_bar_background, " " + windows_icon + " "),
        (inactive_tab_foreground, tab_bar_background, str(active_tab_num_windows)),
    ]

    total_width = sum(len(c) for _, _, c in cells)

    if total_width <= max_width:
        # Right-align full display in available space
        leading = max_width - total_width
        if leading > 0:
            screen.draw(" " * leading)
        for fg, bg, cell in cells:
            screen.cursor.fg = fg
            screen.cursor.bg = bg
            screen.draw(cell)
    else:
        # Truncate: keep last max_width chars
        full_str = "".join(c for _, _, c in cells)
        screen.cursor.fg = inactive_tab_foreground
        screen.cursor.bg = tab_bar_background
        screen.draw(full_str[-max_width:])

    screen.cursor.fg = 0
    screen.cursor.bg = 0


def truncate_str(input_str, max_length):
    if len(input_str) > max_length:
        half = max_length // 2
        return input_str[:half] + "…" + input_str[-half:]
    else:
        return input_str


def get_cwd():
    cwd = ""
    tab_manager = get_boss().active_tab_manager
    if tab_manager is not None:
        window = tab_manager.active_window
        if window is not None:
            cwd = window.cwd_of_child

    cwd_parts = list(Path(cwd).parts)
    if len(cwd_parts) > 1:
        if cwd_parts[1] == "home":
            # replace /home/{{username}}
            cwd_parts = ["~"] + cwd_parts[3:]
            if len(cwd_parts) > 1:
                cwd_parts[0] = "~/"
        else:
            cwd_parts[0] = "/"
    else:
        cwd_parts[0] = "/"

    max_length = 10
    if len(cwd_parts) < 3:
        cwd = cwd_parts[0] + "/".join(
            [
                s if len(s) <= max_length else truncate_str(s, max_length)
                for s in cwd_parts[1:]
            ]
        )
    else:
        cwd = "…/" + "/".join(
            [
                s if len(s) <= max_length else truncate_str(s, max_length)
                for s in cwd_parts[-2:]
            ]
        )

    return folder_icon + " " + cwd
