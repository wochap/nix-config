# source: https://github.com/kovidgoyal/kitty/blob/master/kitty/tab_bar.py

import math
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

    if tab.is_active:
        active_tab_layout_name = tab.layout_name
        active_tab_num_windows = tab.num_windows

    if index == 1:
        _draw_left_status(screen)

    draw_tab_with_separator(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )

    # calculate and insert leading spaces to separate tabs from left status
    if is_last:
        screen_cursor_x = screen.cursor.x
        center_status_length = screen_cursor_x - left_status_length
        leading_spaces = math.ceil(
            (screen.columns - left_status_length * 2 - center_status_length) / 2
        )
        screen.cursor.x = left_status_length
        screen.insert_characters(leading_spaces)
        # TODO: fix tab click handlers
        # https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-11723638
        # tab_manager = get_boss().active_tab_manager
        # tab_manager.tab_bar.cell_ranges = [
        #     (start + leading_spaces, end + leading_spaces)
        #     for (start, end) in tab_manager.tab_bar.cell_ranges
        # ]
        # self.cell_ranges = [(s + leading_spaces, e + leading_spaces) for (s, e) in self.cell_ranges]
        screen.cursor.x = screen_cursor_x + leading_spaces

    if is_last:
        _draw_right_status(screen, is_last)

    return screen.cursor.x


def _draw_left_status(screen: Screen):
    global left_status_length

    cwd = get_cwd()
    cells = [
        (inactive_tab_foreground, tab_bar_background, cwd),
    ]

    left_status_length = 0
    for _, _, cell in cells:
        left_status_length += len(cell)

    # draw right status
    for fg, bg, cell in cells:
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.draw(cell)
    screen.cursor.fg = 0
    screen.cursor.bg = 0

    # update cursor position
    screen.cursor.x = left_status_length
    return screen.cursor.x


def _draw_right_status(screen: Screen, is_last: bool) -> int:
    layout_fg = inactive_tab_foreground if active_tab_layout_name == "fat" else active_tab_background
    layout_icon = layout_icon_by_name[active_tab_layout_name] or default_layout_icon
    cells = [
        # layout name
        (layout_fg, tab_bar_background, " " + layout_icon + " "),
        (layout_fg, tab_bar_background, active_tab_layout_name + " "),
        # num windows
        (inactive_tab_foreground, tab_bar_background, " " + windows_icon + " "),
        (inactive_tab_foreground, tab_bar_background, str(active_tab_num_windows)),
    ]

    # calculate leading spaces to separate tabs from right status
    right_status_length = 0
    for _, _, cell in cells:
        right_status_length += len(cell)
    leading_spaces = 0
    if opts.tab_bar_align == "center":
        leading_spaces = (
            math.ceil((screen.columns - screen.cursor.x) / 2) - right_status_length
        )
    elif opts.tab_bar_align == "left":
        leading_spaces = screen.columns - screen.cursor.x - right_status_length

    # draw leading spaces
    if leading_spaces > 0:
        screen.draw(" " * leading_spaces)

    # draw right status
    for fg, bg, cell in cells:
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.draw(cell)
    screen.cursor.fg = 0
    screen.cursor.bg = 0

    # update cursor position
    screen.cursor.x = max(screen.cursor.x, screen.columns - right_status_length)
    return screen.cursor.x


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
