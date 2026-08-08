#!/usr/bin/env bash

set -euo pipefail

mode=auto
mime_override=

usage() {
  printf 'usage: smart-open [--auto|--gui|--tui] [--mime TYPE] TARGET...\n' >&2
  exit 2
}

while (($#)); do
  case "$1" in
  --auto)
    mode=auto
    shift
    ;;
  --gui)
    mode=gui
    shift
    ;;
  --tui)
    mode=tui
    shift
    ;;
  --mime)
    (($# >= 2)) || usage
    mime_override=$2
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -*)
    [[ $1 == - ]] && break
    usage
    ;;
  *)
    break
    ;;
  esac
done

(($#)) || usage

if [[ $mode == auto ]]; then
  case "${SMART_OPEN_MODE:-}" in
  gui | tui)
    mode=$SMART_OPEN_MODE
    ;;
  *)
    desktop=${XDG_CURRENT_DESKTOP:-}
    desktop=${desktop,,}
    if [[ $desktop != *cage* && -n $desktop && (-n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-}) ]]; then
      mode=gui
    else
      mode=tui
    fi
    ;;
  esac
fi

launch() {
  setsid -f "$@" >/dev/null 2>&1
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'smart-open: required opener not found: %s\n' "$1" >&2
    return 127
  }
}

materialize_stdin() {
  local runtime_dir raw mime suffix target
  runtime_dir=${XDG_RUNTIME_DIR:-/tmp}/smart-open
  mkdir -p -- "$runtime_dir"
  raw=$(mktemp "$runtime_dir/input.XXXXXX")
  cat >"$raw"
  mime=${mime_override:-$(file --brief --mime-type -- "$raw")}

  case "$mime" in
  text/html | application/xhtml+xml) suffix=.html ;;
  application/pdf) suffix=.pdf ;;
  image/jpeg) suffix=.jpg ;;
  image/png) suffix=.png ;;
  image/gif) suffix=.gif ;;
  image/webp) suffix=.webp ;;
  text/calendar) suffix=.ics ;;
  *) suffix= ;;
  esac

  target=$raw$suffix
  mv -- "$raw" "$target"
  printf '%s\n' "$target"
}

open_tui() {
  local target=$1 mime=$2

  if [[ $target =~ ^https?:// ]]; then
    require lynx
    exec lynx "$target"
  fi

  case "$mime" in
  inode/directory)
    require yazi
    exec yazi "$target"
    ;;
  text/html | application/xhtml+xml)
    require lynx
    exec lynx "$target"
    ;;
  text/* | application/json | application/xml | application/javascript)
    require less
    exec less -- "$target"
    ;;
  image/*)
    require chafa
    chafa -- "$target" | less -R
    ;;
  application/pdf)
    require pdftotext
    pdftotext "$target" - | less
    ;;
  audio/*)
    require mpv
    exec mpv --no-video -- "$target"
    ;;
  video/*)
    require mpv
    exec mpv --vo=kitty -- "$target"
    ;;
  application/msword)
    require catdoc
    catdoc -- "$target" | less
    ;;
  application/vnd.ms-excel)
    require xls2csv
    xls2csv "$target" | less
    ;;
  application/vnd.ms-powerpoint)
    require catppt
    catppt "$target" | less
    ;;
  application/zip | application/gzip | application/zstd | application/x-7z* | application/x-bzip* | application/x-compressed-tar | application/x-rar* | application/x-tar | application/x-xz*)
    require atool
    atool --list -- "$target" | less
    ;;
  *)
    printf 'smart-open: no terminal opener for %s\n' "$mime" >&2
    return 1
    ;;
  esac
}

open_gui() {
  local target=$1 mime=$2 terminal

  if [[ $target =~ ^https?:// ]]; then
    require google-chrome-stable
    launch google-chrome-stable "$target"
    return
  fi

  case "$mime" in
  inode/directory)
    require Thunar
    launch Thunar "$target"
    ;;
  text/html | application/xhtml+xml)
    require google-chrome-stable
    launch google-chrome-stable "$target"
    ;;
  text/* | application/json | application/xml | application/javascript)
    terminal=${TERMINAL:-kitty}
    require "$terminal"
    launch "$terminal" -e nvim "$target"
    ;;
  image/*)
    require imv
    launch imv "$target"
    ;;
  application/pdf)
    require zathura
    launch zathura "$target"
    ;;
  audio/* | video/*)
    require mpv
    launch mpv "$target"
    ;;
  application/msword | application/vnd.ms-excel | application/vnd.ms-powerpoint)
    if command -v libreoffice >/dev/null 2>&1; then
      launch libreoffice "$target"
    else
      terminal=${TERMINAL:-kitty}
      require "$terminal"
      launch "$terminal" -e "$0" --tui "$target"
    fi
    ;;
  application/zip | application/gzip | application/zstd | application/x-7z* | application/x-bzip* | application/x-compressed-tar | application/x-rar* | application/x-tar | application/x-xz*)
    require file-roller
    launch file-roller "$target"
    ;;
  *)
    printf 'smart-open: no graphical opener for %s\n' "$mime" >&2
    return 1
    ;;
  esac
}

for original_target in "$@"; do
  target=$original_target
  if [[ $target == - ]]; then
    target=$(materialize_stdin)
  fi

  if [[ $target =~ ^https?:// ]]; then
    mime=text/html
  elif [[ -d $target ]]; then
    mime=inode/directory
  elif [[ -e $target ]]; then
    mime=${mime_override:-$(file --brief --mime-type -- "$target")}
  else
    printf 'smart-open: target does not exist: %s\n' "$target" >&2
    exit 1
  fi

  if [[ $mode == gui ]]; then
    open_gui "$target" "$mime"
  else
    open_tui "$target" "$mime"
  fi
done
