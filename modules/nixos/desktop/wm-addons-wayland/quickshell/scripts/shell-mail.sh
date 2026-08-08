#!/usr/bin/env bash

query='tag:unread and tag:inbox and date:24h..'
last_revision=''
last_count=''

print_count() {
  local result count revision uuid

  result=$(notmuch count --lastmod "$query" 2>/dev/null) || result='0 0 unavailable'
  read -r count revision uuid <<<"$result"

  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  printf '%s\n' "$count"
  last_count="$count"
  last_revision="$revision:$uuid"
}

print_count_if_changed() {
  local result count revision uuid

  result=$(notmuch count --lastmod "$query" 2>/dev/null) || return
  read -r count revision uuid <<<"$result"

  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  if [[ "$revision:$uuid" != "$last_revision" || "$count" != "$last_count" ]]; then
    printf '%s\n' "$count"
    last_count="$count"
    last_revision="$revision:$uuid"
  fi
}

listen() {
  local database_path xapian_path

  database_path=$(notmuch config get database.path 2>/dev/null) || {
    printf '0\n'
    return
  }
  xapian_path="$database_path/.notmuch/xapian"

  print_count

  # Recreate the watch after every event. The timeout also provides a fallback
  # for changes that happen while the watch is being recreated.
  while [[ -d "$xapian_path" ]]; do
    inotifywait -q -t 30 \
      -e close_write -e create -e delete -e move "$xapian_path" >/dev/null 2>&1 || true
    print_count_if_changed
  done
}

command -v notmuch >/dev/null 2>&1 || {
  printf '0\n'
  exit 0
}

case "${1:-}" in
--listen)
  command -v inotifywait >/dev/null 2>&1 || {
    printf '0\n'
    exit 0
  }
  listen
  ;;
--status | '')
  print_count
  ;;
*)
  printf 'Usage: %s [--listen | --status]\n' "$(basename "$0")" >&2
  exit 1
  ;;
esac
