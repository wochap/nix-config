#!/usr/bin/env bash

set -Eeuo pipefail

html_escape() {
  local value=${1-}
  value=${value//&/&amp;}
  value=${value//</&lt;}
  value=${value//>/&gt;}
  value=${value//\"/&quot;}
  value=${value//\'/&apos;}
  printf '%s' "$value"
}

provider_details() {
  local provider=${1,,}

  case "$provider" in
  *codex*) printf '%s\t%s\n' "Codex" "codex" ;;
  *claude*) printf '%s\t%s\n' "Claude Code" "claude-code" ;;
  *qwen*) printf '%s\t%s\n' "Qwen Code" "qwen-code" ;;
  *)
    local display
    display=$(printf '%s' "$1" | tr '_-' '  ' | awk '{
      for (i = 1; i <= NF; i++)
        $i = toupper(substr($i, 1, 1)) substr($i, 2)
      print
    }')
    printf '%s\t%s\n' "${display:-Agent}" "applications-development"
    ;;
  esac
}

notify_update() {
  local envelope=$1
  local status reason_kind reason_summary provider cwd branch session_name
  local context_percent input_tokens output_tokens provider_display icon title event body location usage

  status=$(jq -r '.view.status // empty' <<<"$envelope")
  case "$status" in
  blocked)
    jq -e '(.changed // []) | any(. == "status" or . == "reason")' \
      >/dev/null <<<"$envelope" || return 0
    ;;
  stopped)
    jq -e '(.changed // []) | any(. == "status")' \
      >/dev/null <<<"$envelope" || return 0
    ;;
  *) return 0 ;;
  esac

  provider=$(jq -r '.view.provider // "agent"' <<<"$envelope")
  IFS=$'\t' read -r provider_display icon < <(provider_details "$provider")
  session_name=$(jq -r '.view.session.name // empty' <<<"$envelope")
  title=${session_name:-$provider_display}

  if [[ "$status" == "stopped" ]]; then
    event="Finished"
  else
    reason_kind=$(jq -r '.view.reason.kind // empty' <<<"$envelope")
    case "$reason_kind" in
    approval) event="Agent needs your permission" ;;
    input) event="Agent needs your input" ;;
    *) event="Agent needs your attention" ;;
    esac
  fi

  cwd=$(jq -r '.view.cwd // empty' <<<"$envelope")
  [[ -n "$cwd" ]] && cwd=${cwd/#$HOME/\~}
  branch=$(jq -r '.view.repository.branch // empty' <<<"$envelope")
  location=$cwd
  if [[ -n "$branch" ]]; then
    [[ -n "$location" ]] && location+=" · "
    location+=$branch
  fi

  body=$(html_escape "$event")
  [[ -n "$location" ]] && body+="<br>$(html_escape "$location")"

  reason_summary=$(jq -r '.view.reason.summary // empty' <<<"$envelope")
  if [[ "$status" == "blocked" && -n "$reason_summary" ]]; then
    body+="<br><i>$(html_escape "$reason_summary")</i>"
  fi

  context_percent=$(jq -r '.view.usage.context_window_percent // empty' <<<"$envelope")
  input_tokens=$(jq -r '.view.usage.input_tokens // empty' <<<"$envelope")
  output_tokens=$(jq -r '.view.usage.output_tokens // empty' <<<"$envelope")
  usage=""
  [[ -n "$context_percent" ]] && usage="Context: ${context_percent}%"
  if [[ -n "$input_tokens" ]]; then
    [[ -n "$usage" ]] && usage+=" · "
    usage+="In: $input_tokens"
  fi
  if [[ -n "$output_tokens" ]]; then
    [[ -n "$usage" ]] && usage+=" · "
    usage+="Out: $output_tokens"
  fi
  [[ -n "$usage" ]] && body+="<br>$(html_escape "$usage")"

  notify-send \
    --app-name="sessiontap-notify" \
    --app-icon="$icon" \
    --icon="$icon" \
    --urgency="$([[ "$status" == "blocked" ]] && printf critical || printf normal)" \
    --hint=string:custom-sound:message \
    "$title" \
    "$body"
}

consume_updates() {
  local envelope
  while IFS= read -r envelope; do
    jq -e '.type == "update" and (.view | type == "object")' \
      >/dev/null 2>&1 <<<"$envelope" || continue
    notify_update "$envelope"
  done
}

if [[ ${1-} == "--stdin" ]]; then
  consume_updates
else
  consume_updates < <(sessiontap-hub listen)
fi
