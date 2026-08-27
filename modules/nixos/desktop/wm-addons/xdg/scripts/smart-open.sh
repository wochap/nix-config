#!/usr/bin/env bash

set -euo pipefail

if [[ ${SMART_OPEN_DEBUG:-} ]]; then
  log_dir=${XDG_RUNTIME_DIR:-/tmp}/smart-open
  if mkdir -p -- "$log_dir" 2>/dev/null; then
    {
      printf '%(%Y-%m-%dT%H:%M:%S%z)T pid=%d argv:' -1 "$$"
      printf ' %q' "$@"
      printf '\n'
    } >>"$log_dir/argv.log" 2>/dev/null || :
  fi
fi

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
  application/vnd.openxmlformats-officedocument.wordprocessingml.document) suffix=.docx ;;
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet) suffix=.xlsx ;;
  application/vnd.openxmlformats-officedocument.presentationml.presentation) suffix=.pptx ;;
  *) suffix= ;;
  esac

  target=$raw
  if [[ -n $suffix ]]; then
    target=$raw$suffix
    mv -- "$raw" "$target"
  fi
  printf '%s\n' "$target"
}

office_to_text() (
  local target=$1 runtime_dir output_dir pdf
  require libreoffice
  require pdftotext
  runtime_dir=${XDG_RUNTIME_DIR:-/tmp}/smart-open
  output_dir=$(mktemp -d "$runtime_dir/office.XXXXXX")
  trap 'rm -rf -- "$output_dir"' EXIT
  libreoffice --headless --convert-to pdf --outdir "$output_dir" "$target" >/dev/null
  pdf=$output_dir/$(basename "${target%.*}").pdf
  pdftotext "$pdf" - | less
)

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
  application/vnd.openxmlformats-officedocument.wordprocessingml.document | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | application/vnd.openxmlformats-officedocument.presentationml.presentation)
    office_to_text "$target"
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

gui_handler() {
  local mime=$1

  case "$mime" in
  x-scheme-handler/http | text/html | application/xhtml+xml) printf 'web\n' ;;
  inode/directory) printf 'directory\n' ;;
  text/* | application/json | application/xml | application/javascript | application/x-subrip | application/x-srt) printf 'text\n' ;;
  image/*) printf 'image\n' ;;
  application/pdf) printf 'pdf\n' ;;
  audio/* | video/*) printf 'media\n' ;;
  application/msword | application/vnd.ms-excel | application/vnd.ms-powerpoint | application/vnd.openxmlformats-officedocument.wordprocessingml.document | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | application/vnd.openxmlformats-officedocument.presentationml.presentation) printf 'office\n' ;;
  application/zip | application/gzip | application/zstd | application/x-7z* | application/x-bzip* | application/x-compressed-tar | application/x-rar* | application/x-tar | application/x-xz*) printf 'archive\n' ;;
  *) printf 'fallback:%s\n' "$mime" ;;
  esac
}

open_gui() {
  local handler=$1 terminal
  shift

  case "$handler" in
  web)
    require google-chrome-stable
    launch google-chrome-stable "$@"
    ;;
  directory)
    require Thunar
    launch Thunar "$@"
    ;;
  text)
    require kitty
    launch kitty --single-instance -o window_padding_width=0 -e nvim "$@"
    ;;
  image)
    require imv
    launch imv "$@"
    ;;
  pdf)
    require zathura
    launch zathura "$@"
    ;;
  media)
    require mpv
    launch mpv "$@"
    ;;
  office)
    if command -v libreoffice >/dev/null 2>&1; then
      launch libreoffice "$@"
    else
      terminal=${TERMINAL:-kitty}
      require "$terminal"
      launch "$terminal" -e "$0" --tui "$@"
    fi
    ;;
  archive)
    require file-roller
    launch file-roller "$@"
    ;;
  fallback:*)
    printf 'smart-open: no graphical opener for %s\n' "${handler#fallback:}" >&2
    ;;
  esac
}

gui_targets=()
gui_handlers=()

for original_target in "$@"; do
  target=$original_target
  if [[ $target == - ]]; then
    target=$(materialize_stdin)
  fi

  if [[ $target =~ ^https?:// ]]; then
    mime=x-scheme-handler/http
  elif [[ -d $target ]]; then
    mime=inode/directory
  elif [[ -e $target ]]; then
    mime=${mime_override:-$(file --brief --mime-type -- "$target")}
  else
    printf 'smart-open: target does not exist: %s\n' "$target" >&2
    exit 1
  fi

  if [[ $mode == gui ]]; then
    gui_targets+=("$target")
    gui_handlers+=("$(gui_handler "$mime")")
  else
    open_tui "$target" "$mime"
  fi
done

processed=()
for ((i = 0; i < ${#gui_targets[@]}; i++)); do
  [[ ${processed[i]:-} ]] && continue

  batch=()
  for ((j = i; j < ${#gui_targets[@]}; j++)); do
    if [[ ${gui_handlers[j]} == "${gui_handlers[i]}" ]]; then
      batch+=("${gui_targets[j]}")
      processed[j]=1
    fi
  done
  open_gui "${gui_handlers[i]}" "${batch[@]}"
done
