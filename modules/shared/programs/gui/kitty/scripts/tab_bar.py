import math
from kitty.fast_data_types import Screen, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_separator,
)

opts = get_options()

surface1 = as_rgb(int("45475A", 16))
window_icon = ""
layout_icon = ""

active_tab_layout_name = ""
active_tab_num_windows = 1


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
    end = draw_tab_with_separator(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
    _draw_right_status(
        screen,
        is_last,
    )
    return end


def _draw_right_status(screen: Screen, is_last: bool) -> int:
    if not is_last:
        return screen.cursor.x

    cells = [
        # layout name
        (surface1, screen.cursor.bg, " " + layout_icon + " "),
        (surface1, screen.cursor.bg, active_tab_layout_name + " "),
        # num windows
        (surface1, screen.cursor.bg, " " + window_icon + " "),
        (surface1, screen.cursor.bg, str(active_tab_num_windows) + " "),
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
