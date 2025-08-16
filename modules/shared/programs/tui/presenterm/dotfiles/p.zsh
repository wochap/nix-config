# HACK: remove padding inside kitty
# HACK: increase font size inside kitty
function run-present-kmode() {
  if [[ -n $KITTY_PID ]]; then
    kitty @ set-spacing padding=0
    kitty @ set-font-size 14
    "$@"
    kitty @ set-spacing padding=7
    kitty @ set-font-size 10
  else
    "$@"
  fi
}

function p() {
  session="$(
    cat <<EOF
new_tab presenterm
launch zsh -i -c 'run-present-kmode presenterm $@'
EOF
  )"
  echo "$session" | kitty -o font_family="DejaVu Sans Mono" -o bold_font="auto" -o italic_font="auto" -o bold_italic_font="auto" -o inactive_text_alpha=1 --session -
}

