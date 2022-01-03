#!/usr/bin/env bash

if [ $# = 0 ]; then
    cat <<EOF
Usage: $(basename "${0}") process_name [executable_name] [--take-first]
    process_name       As recognized by 'xdo' command
    executable_name    As used for launching from terminal
    --take-first       In case 'xdo' returns multiple process IDs
EOF
    exit 0
fi

# Get id of process by class name and then fallback to instance name
id=$(xdo id -N "${1}" || xdo id -n "${1}")

executable=${1}
shift

while [ -n "${1}" ]; do
    case ${1} in
    --take-first)
        id=$(head -1 <<<"${id}" | cut -f1 -d' ')
        ;;
    *)
        executable=${1}
        ;;
    esac
    shift
done

if [ -z "${id}" ]; then
    ${executable}
else
    while read -r instance; do
        bspc node "${instance}" --flag hidden --to-monitor focused --focus
    done <<<"${id}"
fi

