#!/usr/bin/env bash

# source theme colors
source "$HOME/.config/scripts/theme-colors.sh"

get_tmux_option() {
  local option=$1
  local default_value="$2"
  # shellcheck disable=SC2155
  local option_value=$(tmux show-options -gqv "$option")
  if [ -n "$option_value" ]; then
    echo "$option_value"
    return
  fi
  echo "$default_value"
}

windows_icon=""
window_icon="󰓩"
session_icon=""
folder_icon="󰉖"
pane_icon=""
bell_icon="󰂞"
activity_icon="󱅫"
host_icon="󰒋"
user_icon=""
default_layout_icon=""
declare -A layout_icon_by_name
layout_icon_by_name["fat"]=""
layout_icon_by_name["tall"]=""
layout_icon_by_name["zoom"]=""
layout_icon_by_name["tiled"]=""

hostname=$(get_tmux_option "@hostname" "glegion")
username=$(get_tmux_option "@username" "gean")
window_index="#{s/0/⁰/g;s/1/¹/g;s/2/²/g;s/3/³/g;s/4/⁴/g;s/5/⁵/g;s/6/⁶/g;s/7/⁷/g;s/8/⁸/g;s/9/⁹/g:window_index}"
pane_index="#{s/0/⁰/g;s/1/¹/g;s/2/²/g;s/3/³/g;s/4/⁴/g;s/5/⁵/g;s/6/⁶/g;s/7/⁷/g;s/8/⁸/g;s/9/⁹/g:pane_index}"
window_flags="#{?window_bell_flag,${bell_icon} ,}#{?window_activity_flag,${activity_icon} ,}"
# args passed to tmux-tab-name: path, command, pane_title, window_name,
# automatic-rename flag, host, window count
tab_args="\"#{pane_current_path}\" \"#{pane_current_command}\" \"#{pane_title}\" \"#{window_name}\" \"#{automatic-rename}\" \"#{host}\" \"#{session_windows}\""
# automatic-rename-format computes window_name, so window_name/auto-rename are
# dummied out here to avoid a self-reference (active mode ignores them anyway)
rename_args="\"#{pane_current_path}\" \"#{pane_current_command}\" \"#{pane_title}\" \"\" \"on\" \"#{host}\" \"#{session_windows}\""
host_module="#{?#{!=:#{host},${hostname}},${host_icon} #H  ,}"
user_module="#{?#{!=:#(whoami),${username}},${user_icon} #(whoami)  ,}"
prefix_module="#{?client_prefix,prefix  ,}"
sync_module="#{?synchronize-panes,sync  ,}"
zoom_module="#{?window_zoomed_flag,${layout_icon_by_name["zoom"]} zoom  ,}"

tmux set-option -g status-position "bottom"
tmux set-option -g status-style bg=default,fg=default
tmux set-option -g status-justify "absolute-centre"
tmux set-option -g status-left "#[bg=default,fg=${surface1}] ${pane_index}${pane_icon} #(tmux-tab-name left ${tab_args})"
tmux set-option -g status-right "#[bg=default,fg=${lavender}]${prefix_module}${sync_module}${zoom_module}#[bg=default,fg=${red}]${user_module}${host_module}#[bg=default,fg=${surface1}]${windows_icon} #{window_panes}  ${session_icon} #S "
tmux set-option -g automatic-rename-format "#(tmux-tab-name active ${rename_args})"
tmux set-option -g window-status-format "#[bg=default,fg=${surface1}]  ${window_index} ${window_icon} #(tmux-tab-name inactive ${tab_args})${window_flags}  #[bg=default,fg=default]"
tmux set-option -g window-status-current-format "#[bg=default,fg=${lavender}]#[bg=${lavender},fg=${base}] ${window_index} ${window_icon} #(tmux-tab-name active ${tab_args})${window_flags} #[bg=default,fg=${lavender}]#[bg=default,fg=default]"

# vim: ft=bash
