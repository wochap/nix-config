#!/usr/bin/env bash

# Get id of process by class name and then fallback to instance name
id=$(xdo id -N "${1}" || xdo id -n "${1}")

executable=${1}
shift

while [ -n "${1}" ]; do
  case ${1} in
  *)
    id=$(head -1 <<<"${id}" | cut -f1 -d' ')
    ;;
  esac
  shift
done

if [ -z "${id}" ]; then
  coproc $executable
else
  while read -r instance; do
    bspc node "${instance}" --focus
  done <<<"${id}"
fi
