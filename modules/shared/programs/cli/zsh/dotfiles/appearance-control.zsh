# inspiration: https://github.com/alberti42/zsh-appearance-control

[[ -o interactive ]] || return 0

# The global array that stores all registered hook functions
typeset -ga theme_change_hooks

# 1. The Registration Function
# Usage: add-theme-hook my_custom_function
add-theme-hook() {
    local hook_name="$1"
    # Only add if it's not already in the array (prevents duplicates)
    if (( ${theme_change_hooks[(I)$hook_name]} == 0 )); then
        theme_change_hooks+=("$hook_name")
    fi
}

# 2. The Execution Engine
_execute_theme_hooks() {
    local theme_state="${DEFAULT_COLOR_SCHEME:-dark}"
    if command -v color-scheme >/dev/null 2>&1; then
      theme_state=$(color-scheme print)
    fi

    # Loop through all registered hooks and execute them, passing the state
    for hook in "${theme_change_hooks[@]}"; do
        if (( $+functions[$hook] )); then
            "$hook" "$theme_state"
        fi
    done
}

# 3. Safely chain TRAPUSR1
_THEME_NEEDS_SYNC=0
if (( $+functions[TRAPUSR1] )); then
    functions -c TRAPUSR1 _previous_trapusr1
fi

TRAPUSR1() {
    _THEME_NEEDS_SYNC=1
    if (( $+functions[_previous_trapusr1] )); then
        _previous_trapusr1
    fi
}

# 4. The Zsh precmd hook to safely apply the changes
_theme_precmd_hook() {
    if (( _THEME_NEEDS_SYNC )); then
        _execute_theme_hooks
        _THEME_NEEDS_SYNC=0
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _theme_precmd_hook
