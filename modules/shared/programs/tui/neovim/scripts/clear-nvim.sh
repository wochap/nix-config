#!/usr/bin/env bash

items=$(find $HOME/.config -maxdepth 2 -name "init.lua" -type f -execdir sh -c 'pwd | xargs basename' \;)
selected=$(printf "%s\n" "${items[@]}" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} --preview 'lsd -l -A --tree --depth=1 --color=always --blocks=size,name ~/.config/{} | head -200'" fzf)
if [[ -z $selected ]]; then
  return 0
fi

confirm_message="Are you sure you want to delete the share, state, and cache for $selected?"
confirm_branch=$(gum confirm --no-show-help "$confirm_message" && echo 1 || echo 0)

if [ "$confirm_branch" -eq 0 ]; then
  exit 0
fi

trash-put -rf "$HOME/.local/share/$selected"
trash-put -rf "$HOME/.local/state/$selected"
trash-put -rf "$HOME/.cache/$selected"
