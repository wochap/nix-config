#!/usr/bin/env bash

selected=$(cat "$HOME/cht/cht-languages.txt" "$HOME/cht/cht-commands.txt" | fzf)
if [[ -z $selected ]]; then
  exit 0
fi

read -p "Enter Query: " query

if grep -qs "$selected" "$HOME/cht/cht-languages.txt;" then
  query=$(echo $query | tr ' ' '+')
  kitty @ launch --type overlay zsh -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
  kitty @ launch --type overlay zsh -c "curl -s cht.sh/$selected~$query | less"
fi
