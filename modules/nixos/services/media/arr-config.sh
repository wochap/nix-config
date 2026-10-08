# media-{sonarr,radarr}-config
#
# Adds what Sonarr or Radarr misses from the media stack: the admin login, the
# root folder and a qBittorrent download client, all through the documented
# v3 API. Leaves existing entries alone, except that a
# client pointing at the other qBittorrent host (media-qbittorrent vs
# media-vpn) follows the VPN setting. ARR_* and QBT_* come from the Nix module.

api_key=$(read_secret "$ARR_API_KEY_FILE")

api() {
  curl -fsS -H @<(printf 'X-Api-Key: %s\n' "$api_key") \
    -H "Content-Type: application/json" "$@"
}

wait_until "$ARR_NAME at $ARR_URL" api -o /dev/null "$ARR_URL/api/v3/system/status"

servarr_ensure_login "$ARR_URL/api/v3"

# Root folder
if api "$ARR_URL/api/v3/rootfolder" |
  jq -e --arg p "$ARR_ROOT_FOLDER" 'any(.[]; (.path | rtrimstr("/")) == $p)' >/dev/null; then
  log "root folder $ARR_ROOT_FOLDER present"
else
  jq -n --arg p "$ARR_ROOT_FOLDER" '{path: $p}' |
    api -X POST --data @- "$ARR_URL/api/v3/rootfolder" >/dev/null
  log "added root folder $ARR_ROOT_FOLDER"
fi

# Hardlinks are the default; only report when someone turned them off.
if ! api "$ARR_URL/api/v3/config/mediamanagement" | jq -e '.copyUsingHardlinks' >/dev/null; then
  warn "Use Hardlinks instead of Copy is off; imports will copy files"
fi

# Download client
clients=$(api "$ARR_URL/api/v3/downloadclient" | jq -c '[.[] | select(.implementation == "QBittorrent")]')
if [ "$(jq length <<<"$clients")" -eq 0 ]; then
  api "$ARR_URL/api/v3/downloadclient/schema" |
    jq --arg host "$QBT_HOST" --argjson port "$QBT_PORT" \
      --arg field "$ARR_CATEGORY_FIELD" --arg category "$ARR_CATEGORY" '
      first(.[] | select(.implementation == "QBittorrent"))
      | . + {name: "qBittorrent", enable: true}
      | .fields |= map(
          if .name == "host" then .value = $host
          elif .name == "port" then .value = $port
          elif .name == $field then .value = $category
          else . end)' |
    api -X POST --data @- "$ARR_URL/api/v3/downloadclient?forceSave=true" >/dev/null
  log "added qBittorrent download client ($QBT_HOST:$QBT_PORT, category $ARR_CATEGORY)"
else
  # Only rewrite hosts this module manages, never a custom one.
  while IFS= read -r client; do
    id=$(jq -r .id <<<"$client")
    host=$(jq -r '.fields[] | select(.name == "host") | .value' <<<"$client")
    if [ "$host" != "$QBT_HOST" ] && [[ " $QBT_KNOWN_HOSTS " == *" $host "* ]]; then
      jq --arg host "$QBT_HOST" '.fields |= map(if .name == "host" then .value = $host else . end)' <<<"$client" |
        api -X PUT --data @- "$ARR_URL/api/v3/downloadclient/$id?forceSave=true" >/dev/null
      log "download client $id: host $host -> $QBT_HOST"
    else
      log "download client $id ($host) left as is"
    fi
  done < <(jq -c '.[]' <<<"$clients")
fi
