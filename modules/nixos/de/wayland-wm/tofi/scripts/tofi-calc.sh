#!/usr/bin/env bash

history_file_path=/tmp/calc_history

if [ ! -f "$history_file_path" ]; then
  touch "$history_file_path"
fi

# options=$(cat "$history_file_path")
options=""
selected="$(echo -e "$options" |
  tofi \
    --require-match false \
    --prompt-text "calc" \
    --config "$HOME/.config/tofi/one-line")"

if [[ -n "$selected" ]]; then
  # calculate
  input=${selected%%=*}
  result=$(echo "scale=2; $input" | bc)

  # save to history
  temp_file=$(mktemp)
  line="$input = $result"
  echo "$line" >"$temp_file"
  cat "$history_file_path" >>"$temp_file"
  mv "$temp_file" "$history_file_path"

  # copy result to clipboard
  echo -n "$result" | wl-copy
fi
