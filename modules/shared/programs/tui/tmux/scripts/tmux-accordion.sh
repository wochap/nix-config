#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
target="${2:-$(tmux display-message -p '#{window_id}')}"

window_exists() {
  tmux display-message -p -t "$target" '#{window_id}' >/dev/null 2>&1
}

accordion_enabled() {
  [[ "$(tmux show-options -wv -t "$target" @accordion-mode 2>/dev/null || true)" == 1 ]]
}

apply_layout() {
  accordion_enabled || return 0

  tmux select-layout -t "$target" even-vertical
  tmux resize-pane -t "$target" -y 9999
}

window_exists || exit 0

case "$action" in
enable)
  if ! accordion_enabled; then
    border_status="$(tmux display-message -p -t "$target" '#{pane-border-status}')"
    tmux set-option -w -t "$target" @accordion-border-status "$border_status"
    tmux set-option -w -t "$target" @accordion-mode 1
    tmux set-option -w -t "$target" pane-border-status top
  fi
  apply_layout
  ;;
apply)
  apply_layout
  ;;
disable)
  layout="${3:-}"
  case "$layout" in
  main-vertical | main-horizontal | tiled) ;;
  *)
    printf 'tmux-accordion: invalid layout: %s\n' "$layout" >&2
    exit 2
    ;;
  esac

  if accordion_enabled; then
    border_status="$(tmux show-options -wv -t "$target" @accordion-border-status)"
    tmux set-option -w -t "$target" pane-border-status "$border_status"
    tmux set-option -wu -t "$target" @accordion-mode
    tmux set-option -wu -t "$target" @accordion-border-status
  fi
  tmux select-layout -t "$target" "$layout"
  ;;
*)
  printf 'usage: tmux-accordion {enable|apply|disable} [target] [layout]\n' >&2
  exit 2
  ;;
esac
