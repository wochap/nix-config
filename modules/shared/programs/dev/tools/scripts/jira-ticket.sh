#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s [--email EMAIL] [--token TOKEN | --token-file FILE] <ticket-url>\n' "${0##*/}" >&2
}

email=${JIRA_EMAIL:-}
token=${JIRA_API_TOKEN:-}
token_file=
ticket_url=

while (($#)); do
  case $1 in
  --email)
    (($# >= 2)) || {
      usage
      exit 2
    }
    email=$2
    shift 2
    ;;
  --token)
    (($# >= 2)) || {
      usage
      exit 2
    }
    token=$2
    token_file=
    shift 2
    ;;
  --token-file)
    (($# >= 2)) || {
      usage
      exit 2
    }
    token_file=$2
    token=
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  -*)
    printf 'error: unknown option: %s\n' "$1" >&2
    usage
    exit 2
    ;;
  *)
    [[ -z $ticket_url ]] || {
      usage
      exit 2
    }
    ticket_url=$1
    shift
    ;;
  esac
done

if (($#)); then
  [[ -z $ticket_url && $# == 1 ]] || {
    usage
    exit 2
  }
  ticket_url=$1
fi

if [[ -z $ticket_url || -z $email ]]; then
  printf 'error: provide a ticket URL and Jira email via --email or JIRA_EMAIL\n' >&2
  usage
  exit 2
fi

if [[ -n $token_file ]]; then
  if [[ ! -r $token_file ]]; then
    printf 'error: token file is not readable: %s\n' "$token_file" >&2
    exit 1
  fi
  token=$(<"$token_file")
fi

if [[ -z $token ]]; then
  printf 'error: provide a token via --token, --token-file, or JIRA_API_TOKEN\n' >&2
  exit 2
fi

readonly ticket_url email token

ticket_path=${ticket_url%%[?#]*}
ticket_path=${ticket_path%/}
readonly ticket_key=${ticket_path##*/}

if [[ ! $ticket_url =~ ^https?://[^/]+/browse/[^/?#]+/?([?#].*)?$ ]] ||
  [[ ! $ticket_key =~ ^[[:alnum:]][[:alnum:]_-]*-[0-9]+$ ]]; then
  printf 'error: expected a Jira ticket URL such as https://example.atlassian.net/browse/PROJ-123\n' >&2
  exit 2
fi

readonly jira_site=${ticket_url%%/browse/*}

tenant_info=$(curl --fail-with-body --silent --show-error \
  --header 'Accept: application/json' \
  "$jira_site/_edge/tenant_info")
cloud_id=$(jq --exit-status --raw-output '.cloudId | select(type == "string" and length > 0)' \
  <<<"$tenant_info")
readonly api_base="https://api.atlassian.com/ex/jira/$cloud_id/rest/api/3"
readonly jira_credentials="$email:$token"

if ! field_response=$(curl --fail-with-body --silent --show-error \
  --user "$jira_credentials" \
  --header 'Accept: application/json' \
  "$api_base/field"); then
  if [[ -n $field_response ]]; then
    jq --raw-output '.message // .errorMessages[]? // .' <<<"$field_response" >&2
  fi
  exit 1
fi

checklist_field_ids=$(jq --raw-output '[
  .[]
  | select(.name | ascii_downcase | contains("checklist"))
  | .id
] | join(",")' <<<"$field_response")

issue_fields='summary,description,attachment'
if [[ -n $checklist_field_ids ]]; then
  issue_fields+=",$checklist_field_ids"
fi

if ! jira_response=$(curl --fail-with-body --silent --show-error \
  --user "$jira_credentials" \
  --header 'Accept: application/json' \
  --get \
  --data-urlencode "fields=$issue_fields" \
  --data-urlencode 'properties=checklist' \
  "$api_base/issue/$ticket_key"); then
  if [[ -n $jira_response ]]; then
    jq --raw-output '.message // .errorMessages[]? // .' <<<"$jira_response" >&2
  fi
  exit 1
fi

if ! comment_response=$(curl --fail-with-body --silent --show-error \
  --user "$jira_credentials" \
  --header 'Accept: application/json' \
  --get \
  --data-urlencode 'maxResults=100' \
  --data-urlencode 'orderBy=created' \
  "$api_base/issue/$ticket_key/comment"); then
  if [[ -n $comment_response ]]; then
    jq --raw-output '.message // .errorMessages[]? // .' <<<"$comment_response" >&2
  fi
  exit 1
fi

jq --arg url "$ticket_url" \
  --argjson field_catalog "$field_response" \
  --argjson comment_response "$comment_response" '
  .fields as $fields
  | ($field_catalog | map(select(.name | ascii_downcase | contains("checklist")))) as $checklist_fields
  | {
      title: $fields.summary,
      url: $url,
      description: $fields.description,
      attachments: [
        $fields.attachment[]?
        | {
            id,
            filename,
            mimeType,
            size,
            content,
            thumbnail
          }
      ],
      comments: [
        $comment_response.comments[]?
        | {
            id,
            author: (.author.displayName // .author.accountId),
            created,
            updated,
            body
          }
      ],
      checklist: [
        (if .properties.checklist != null then
          {
            name: "Checklist",
            value: .properties.checklist
          }
        else
          empty
        end),
        ($checklist_fields[]
          | select($fields[.id] != null)
          | {
              name,
              value: $fields[.id]
            })
      ]
    }
' <<<"$jira_response"
