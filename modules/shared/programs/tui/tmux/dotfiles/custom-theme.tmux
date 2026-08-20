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
# signal bell/activity by colour (the nerd-font bell glyphs render as boxes in
# foot): bell -> red, activity -> yellow, else the normal tab colour
inactive_color="#{?window_bell_flag,${peach},#{?window_activity_flag,${yellow},${surface1}}}"
inactive_bg="#{?window_bell_flag,${background},#{?window_activity_flag,${background},default}}"
active_color="#{?window_bell_flag,${peach},#{?window_activity_flag,${yellow},${lavender}}}"
# native tab title (no script, no fork): a meaningful pane_title wins; at a
# shell prompt fall back to the cwd basename, elsewhere the command basename.
shell_or_cmd="#{?#{m:*zsh*,#{pane_current_command}},#{b:pane_current_path},#{?#{m:*bash*,#{pane_current_command}},#{b:pane_current_path},#{?#{m:*fish*,#{pane_current_command}},#{b:pane_current_path},#{?#{m:*sh*,#{pane_current_command}},#{b:pane_current_path},#{b:pane_current_command}}}}}"
tab_title="#{?#{==:#{pane_title},#{host}},${shell_or_cmd},#{pane_title}}"
# Read the title LIVE at draw time (not the cached #W) so a cd + refresh-client
# shows the new name immediately; a manual `rename-window` turns automatic-rename
# off, in which case the custom window name (#W) is shown instead.
tab_display="#{?#{automatic-rename},${tab_title},#W}"
# Limit status-bar tab titles to 30 characters (29 characters plus an ellipsis).
# pane-border-format uses tab_title directly and remains untruncated.
tab_display="#{=/29/…:${tab_display}}"
# status-left cwd with $HOME collapsed to ~ (baked once, tmux swaps natively)
status_left_path="#{s|${HOME}|~|:pane_current_path}"
host_module="#{?#{!=:#{host},${hostname}},${host_icon} #H  ,}"
# resolve user once at load; avoids a #(whoami) fork on every status redraw
current_user="$(id -un)"
user_module="#{?#{!=:${current_user},${username}},${user_icon} ${current_user}  ,}"
prefix_module="#{?client_prefix,prefix  ,}"
sync_module="#{?synchronize-panes,sync  ,}"
zoom_module="#{?window_zoomed_flag,${layout_icon_by_name["zoom"]} zoom  ,}"

tmux set-option -g pane-border-lines single
tmux set-option -g popup-border-lines rounded

tmux set-option -g message-style "fg=${teal},bg=${backgroundOverlay},align=centre"
tmux set-option -g message-command-style "fg=${teal},bg=${backgroundOverlay},align=centre"
tmux set-option -g menu-selected-style "fg=${text},bold,bg=${backgroundOverlay}"
tmux set-option -g pane-border-style "fg=${border}"
tmux set-option -g pane-active-border-style "fg=${primary}"
tmux set-option -g pane-border-format "#[bg=default,fg=${border}] ${pane_index} ${pane_icon} ${tab_title} #[default]"
tmux set-option -g popup-style "bg=${background},fg=${text}"
tmux set-option -g popup-border-style "fg=${surface1}"
tmux set-option -g mode-style "bg=${surface0},bold"
tmux set-option -g clock-mode-colour "${blue}"

tmux set-option -g status-position "bottom"
tmux set-option -g status-style bg=default,fg=default
tmux set-option -g status-justify "absolute-centre"
# tmux-sensible sets these to `reverse`, which swaps fg/bg on bell/activity
# windows and clobbers the colours encoded in window-status-format
tmux set-option -g window-status-bell-style default
tmux set-option -g window-status-activity-style default
# tmux truncates status-left/right to 10 chars by default; allow the full path
tmux set-option -g status-left-length 200
tmux set-option -g status-right-length 200
tmux set-option -g status-left "#[bg=default,fg=${surface1}] ${pane_index}${pane_icon} ${status_left_path}"
tmux set-option -g status-right "#[bg=default,fg=${lavender}]${prefix_module}${sync_module}${zoom_module}#[bg=default,fg=${red}]${user_module}${host_module}#[bg=default,fg=${surface1}]${windows_icon} #{window_panes}  ${session_icon} #S "
tmux set-option -g automatic-rename-format "${tab_title}"
bell_module="#{?window_bell_flag, ${bell_icon},}"
tmux set-option -g window-status-format "#[bg=${inactive_bg},fg=${inactive_color}]  ${window_index} ${window_icon} ${tab_display}${bell_module}  #[bg=default,fg=default]"
tmux set-option -g window-status-current-format "#[bg=default,fg=${active_color}]#[bg=${active_color},fg=${background}] ${window_index} ${window_icon} ${tab_display}${bell_module} #[bg=default,fg=${active_color}]#[bg=default,fg=default]"

# vim: ft=bash
