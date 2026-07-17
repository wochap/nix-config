# inspiration: https://github.com/alberti42/zsh-appearance-control

# -------------------------------------------------------------------
# Zsh Theme Switcher (Signal-Driven with Safe Trap Chaining)
# Trigger via daemon command: killall -USR1 zsh
# -------------------------------------------------------------------

# 1. Do nothing if not in an interactive terminal (e.g., inside a shell script)
[[ -o interactive ]] || return 0

# 2. State flag to track if the theme changed while we were typing or running an app
_THEME_NEEDS_SYNC=0

# 3. Your custom function to swap the theme
_apply_theme_change() {
  notify-send "algo"
  # ---------------------------------------------------------
  # YOUR THEME LOGIC GOES HERE
  # Example: Query your OS or daemon for the current state
  #
  # local theme=$(gsettings get org.gnome.desktop.interface color-scheme)
  # if [[ "$theme" == *"'prefer-dark'"* ]]; then
  #     source ~/.config/zsh/dark-theme.zsh
  # else
  #     source ~/.config/zsh/light-theme.zsh
  # fi
  # ---------------------------------------------------------
}

# 4. Safely chain TRAPUSR1 (so we don't break other plugins)
if (($ + functions[TRAPUSR1])); then
  # If another plugin already uses USR1, copy its function to a backup
  functions -c TRAPUSR1 _previous_trapusr1
fi

TRAPUSR1() {
  # Note the change, but do NOT interrupt the prompt right now
  _THEME_NEEDS_SYNC=1

  # Execute the previous plugin's trap if we backed one up
  if (($ + functions[_previous_trapusr1])); then
    _previous_trapusr1
  fi
}

# 5. The Hook: Safely applies the theme right before a new prompt is drawn
_theme_precmd_hook() {
  if ((_THEME_NEEDS_SYNC)); then
    _apply_theme_change

    # Reset the flag so we don't run this again until the next signal
    _THEME_NEEDS_SYNC=0
  fi
}

# Register the hook natively in Zsh
autoload -Uz add-zsh-hook
add-zsh-hook precmd _theme_precmd_hook

# 6. Run it once on startup to ensure the shell boots with the correct theme
_apply_theme_change
