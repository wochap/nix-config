# ================
# tmux
# ================

# Refresh the tmux status line as soon as the directory changes, so window/tab
# titles and the status-left path update immediately instead of waiting for
# status-interval. Guarded to only run inside tmux and only when $PWD changed.
_tmux_refresh_status_on_cd() {
  [[ -z "$TMUX" ]] && return 0
  if [[ "$PWD" != "$_TMUX_LAST_PWD" ]]; then
    _TMUX_LAST_PWD="$PWD"
    tmux refresh-client -S 2>/dev/null
  fi
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _tmux_refresh_status_on_cd
