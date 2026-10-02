#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

usage() {
  printf 'usage: logstat.sh [-n N] [-s CLASS] [-f text|json|html] [FILE...]\n' >&2
  exit 2
}

top=10
class=""
format=text
files=()

while (($# > 0)); do
  case $1 in
    -n | --top)
      (($# >= 2)) || usage
      [[ $2 =~ ^[1-9][0-9]*$ ]] || usage
      top=$2
      shift 2
      ;;
    -s | --status)
      (($# >= 2)) || usage
      [[ $2 =~ ^[1-5]xx$ ]] || usage
      class=${2:0:1}
      shift 2
      ;;
    -f | --format)
      (($# >= 2)) || usage
      case $2 in text | json | html) format=$2 ;; *) usage ;; esac
      shift 2
      ;;
    --)
      shift
      files+=("$@")
      break
      ;;
    -?*) usage ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done
((${#files[@]} > 0)) || files=(-)

for f in "${files[@]}"; do
  if [[ $f != - && ! -r $f ]]; then
    printf 'logstat: cannot read %s\n' "$f" >&2
    exit 1
  fi
done

declare -A counts=() bytes=()
total_requests=0
total_bytes=0
malformed=0

process() {
  local line path status size extra
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    read -r _ _ path status size extra <<<"$line"
    if [[ -z $size || -n $extra || ! $status =~ ^[1-5][0-9][0-9]$ || ! $size =~ ^([0-9]+|-)$ ]]; then
      malformed=$((malformed + 1))
      continue
    fi
    [[ $size == - ]] && size=0
    [[ -n $class && ${status:0:1} != "$class" ]] && continue
    counts[$path]=$((${counts[$path]:-0} + 1))
    bytes[$path]=$((${bytes[$path]:-0} + 10#$size))
    total_requests=$((total_requests + 1))
    total_bytes=$((total_bytes + 10#$size))
  done
}

for f in "${files[@]}"; do
  if [[ $f == - ]]; then
    process
  else
    process <"$f"
  fi
done

if ((malformed > 0)); then
  printf 'logstat: skipped %d malformed line(s)\n' "$malformed" >&2
fi

ranked=()
if ((${#counts[@]} > 0)); then
  mapfile -t ranked < <(
    for p in "${!counts[@]}"; do printf '%s\t%s\n' "${counts[$p]}" "$p"; done |
      LC_ALL=C sort -t $'\t' -k1,1nr -k2,2 | head -n "$top" | cut -f2-
  )
fi

json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

html_escape() {
  local s=$1
  s=${s//'&'/'&amp;'}
  s=${s//'<'/'&lt;'}
  s=${s//'>'/'&gt;'}
  s=${s//'"'/'&quot;'}
  printf '%s' "$s"
}

case $format in
  text)
    for p in "${ranked[@]}"; do
      printf '%d %d %s\n' "${counts[$p]}" "${bytes[$p]}" "$p"
    done
    printf 'TOTAL %d %d\n' "$total_requests" "$total_bytes"
    ;;
  json)
    out='{"total":{"requests":'"$total_requests"',"bytes":'"$total_bytes"'},"paths":['
    sep=""
    for p in "${ranked[@]}"; do
      out+="$sep"'{"path":"'"$(json_escape "$p")"'","count":'"${counts[$p]}"',"bytes":'"${bytes[$p]}"'}'
      sep=,
    done
    printf '%s]}\n' "$out"
    ;;
  html)
    printf '<table>\n<tr><th>path</th><th>count</th><th>bytes</th></tr>\n'
    for p in "${ranked[@]}"; do
      printf '<tr><td>%s</td><td>%d</td><td>%d</td></tr>\n' "$(html_escape "$p")" "${counts[$p]}" "${bytes[$p]}"
    done
    printf '</table>\n'
    ;;
esac
