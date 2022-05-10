#!/usr/bin/env bash
#reorder desktops based on a list.
#primary or first monitor gets all desktop except one per additional monitor.
#the additional monitors take desktops from the back of the list

[[ "${#BSPWM_DESKTOPS[@]}" != 0 ]] ||
  BSPWM_DESKTOPS=(1 2 3 4 F1 F2 F3 F4)

reordermon() {
  bspc monitor "$1" --reorder-desktops "${@:2}" 2>/dev/null
  bspc monitor "$1" --reset-desktops "${@:2}"
}

mvdesktops() {
  local dm tm
  dm=$1
  shift

  while [[ -n "$1" ]]; do
    tm="$(bspc query --monitors --desktop "$1")"
    [[ "$(bspc query --desktops --monitor "$tm" | wc -l)" -le 1 ]] &&
      bspc monitor "$tm" --add-desktops "$placeholder"
    bspc desktop "$1" --to-monitor "$dm"
    shift
  done
}

placeholder=tempdesktop
mon=($(bspc query --monitors))
fdesk=$(bspc query --desktops --desktop)

if [[ "${#mon[@]}" -gt 1 ]]; then
  if pmon=$(bspc query --monitors --monitor primary); then
    mon=(${mon[@]/"$pmon"/})
  else
    pmon="${mon[0]}"
    unset "mon[0]"
  fi

  di=$((${#BSPWM_DESKTOPS[@]} - ${#mon[@]}))
  [[ "$di" -gt 0 ]] || exit 1
  pdname=("${BSPWM_DESKTOPS[@]::$di}")
  dname=("${BSPWM_DESKTOPS[@]:$di}")
  mvdesktops "$pmon" "${pdname[@]}"

  i=0
  for mi in "${!mon[@]}"; do
    mvdesktops "${mon[$mi]}" "${dname[$((i++))]}"
  done

  reordermon "$pmon" "${pdname[@]}"

  i=0
  for mi in "${!mon[@]}"; do
    reordermon "${mon[$mi]}" "${dname[$((i++))]}"
  done
else
  reordermon "${mon[0]}" "${BSPWM_DESKTOPS[@]}"
fi

bspc desktop "$fdesk" --focus

