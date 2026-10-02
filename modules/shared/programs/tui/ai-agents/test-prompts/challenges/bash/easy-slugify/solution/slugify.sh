#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

if (($# == 0)); then
  printf 'usage: slugify.sh TEXT...\n' >&2
  exit 2
fi

s="$*"
s="${s,,}"
s="${s//+([^a-z0-9])/-}"
s="${s#-}"
s="${s%-}"

if [[ -z $s ]]; then
  exit 1
fi
printf '%s\n' "$s"
