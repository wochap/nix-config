#!/usr/bin/env bash

lavender="#B4BEFE"
surface1="#45475A"
base="#1E1E2E"
windows_icon=""
window_icon="󰓩"
session_icon=""
folder_icon="󰉖"
default_layout_icon=""
declare -A layout_icon_by_name
layout_icon_by_name["fat"]=""
layout_icon_by_name["tall"]=""
layout_icon_by_name["zoom"]=""
layout_icon_by_name["tiled"]=""

window_index="#{s/0/⁰/g;s/1/¹/g;s/2/²/g;s/3/³/g;s/4/⁴/g;s/5/⁵/g;s/6/⁶/g;s/7/⁷/g;s/8/⁸/g;s/9/⁹/g:window_index}"
window_name="#{=/-30/…:window_name}"

tmux set-option -g status-position "bottom"
tmux set-option -g status-style bg=default,fg=default
tmux set-option -g status-justify "absolute-centre"
tmux set-option -g status-left " #[bg=default,fg=${surface1}]${folder_icon} #{b:pane_current_path}"
tmux set-option -g status-right "#[bg=default,fg=${lavender}]#{?client_prefix,prefix ,}#{?window_zoomed_flag,${layout_icon_by_name["zoom"]} zoom ,}#[bg=default,fg=${surface1}]${windows_icon} #{window_panes} ${session_icon} #S "
tmux set-option -g window-status-format "#[bg=default,fg=${surface1}]  ${window_index} ${window_icon} ${window_name}  #[bg=default,fg=default]"
tmux set-option -g window-status-current-format "#[bg=default,fg=${lavender}]#[bg=${lavender},fg=${base}] ${window_index} ${window_icon} ${window_name} #[bg=default,fg=${lavender}]#[bg=default,fg=default]"

# vim: ft=bash
