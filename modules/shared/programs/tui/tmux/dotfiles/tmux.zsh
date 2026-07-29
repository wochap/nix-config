# ================
# tmux
# ================

# Keep the event-driven status bar in sync on cd (status-interval is 0):
#   - select-pane -T feeds the cwd basename to tmux as the pane title (like
#     nvim's titlestring), firing pane-title-changed so the tab title recomputes
#   - refresh-client -S redraws the ~/full status-left even when the basename
#     didn't change (e.g. /a/x -> /b/x)
# Guarded to only run inside tmux and only when $PWD changed.
_tmux_refresh_status_on_cd() {
  [[ -z "$TMUX" ]] && return 0
  if [[ "$PWD" != "$_TMUX_LAST_PWD" ]]; then
    _TMUX_LAST_PWD="$PWD"
    tmux select-pane -T "${PWD:t}" \; refresh-client -S 2>/dev/null
  fi
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _tmux_refresh_status_on_cd
