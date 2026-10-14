# media-{sonarr,radarr,lidarr}-config
#
# Adds what Sonarr, Radarr or Lidarr misses from the media stack: the admin
# login, the root folder and a qBittorrent download client, all through the
# documented API (v3, v1 for Lidarr). Leaves existing entries alone, except that a
# client pointing at the other qBittorrent host (media-qbittorrent vs
# media-vpn) follows the VPN setting. ARR_* and QBT_* come from the Nix module.

api_key=$(read_secret "$ARR_API_KEY_FILE")

api() {
  curl -fsS -H @<(printf 'X-Api-Key: %s\n' "$api_key") \
    -H "Content-Type: application/json" "$@"
}

base="$ARR_URL/api/${ARR_API:-v3}"

wait_until "$ARR_NAME at $ARR_URL" api -o /dev/null "$base/system/status"

servarr_ensure_login "$base"

# Root folder
if api "$base/rootfolder" |
  jq -e --arg p "$ARR_ROOT_FOLDER" 'any(.[]; (.path | rtrimstr("/")) == $p)' >/dev/null; then
  log "root folder $ARR_ROOT_FOLDER present"
elif [ -n "${ARR_ROOT_FOLDER_NAME:-}" ]; then
  # Lidarr's root folders also carry a name and the defaults for new artists:
  # the first quality profile and the first metadata profile except "None".
  quality=$(api "$base/qualityprofile" | jq -e 'first(.[].id)') ||
    die "no quality profile in $ARR_NAME"
  metadata=$(api "$base/metadataprofile" | jq -e 'first(.[] | select(.name != "None") | .id)') ||
    die "no metadata profile in $ARR_NAME"
  jq -n --arg p "$ARR_ROOT_FOLDER" --arg name "$ARR_ROOT_FOLDER_NAME" \
    --argjson quality "$quality" --argjson metadata "$metadata" '{
      path: $p,
      name: $name,
      defaultQualityProfileId: $quality,
      defaultMetadataProfileId: $metadata,
      defaultMonitorOption: "all",
      defaultNewItemMonitorOption: "all",
      defaultTags: []
    }' |
    api -X POST --data @- "$base/rootfolder" >/dev/null
  log "added root folder $ARR_ROOT_FOLDER ($ARR_ROOT_FOLDER_NAME)"
else
  jq -n --arg p "$ARR_ROOT_FOLDER" '{path: $p}' |
    api -X POST --data @- "$base/rootfolder" >/dev/null
  log "added root folder $ARR_ROOT_FOLDER"
fi

# Hardlinks are the default; only report when someone turned them off.
if ! api "$base/config/mediamanagement" | jq -e '.copyUsingHardlinks' >/dev/null; then
  warn "Use Hardlinks instead of Copy is off; imports will copy files"
fi

# Download client
clients=$(api "$base/downloadclient" | jq -c '[.[] | select(.implementation == "QBittorrent")]')
if [ "$(jq length <<<"$clients")" -eq 0 ]; then
  api "$base/downloadclient/schema" |
    jq --arg host "$QBT_HOST" --argjson port "$QBT_PORT" \
      --arg field "$ARR_CATEGORY_FIELD" --arg category "$ARR_CATEGORY" '
      first(.[] | select(.implementation == "QBittorrent"))
      | . + {name: "qBittorrent", enable: true}
      | .fields |= map(
          if .name == "host" then .value = $host
          elif .name == "port" then .value = $port
          elif .name == $field then .value = $category
          else . end)' |
    api -X POST --data @- "$base/downloadclient?forceSave=true" >/dev/null
  log "added qBittorrent download client ($QBT_HOST:$QBT_PORT, category $ARR_CATEGORY)"
else
  # Only rewrite hosts this module manages, never a custom one.
  while IFS= read -r client; do
    id=$(jq -r .id <<<"$client")
    host=$(jq -r '.fields[] | select(.name == "host") | .value' <<<"$client")
    if [ "$host" != "$QBT_HOST" ] && [[ " $QBT_KNOWN_HOSTS " == *" $host "* ]]; then
      jq --arg host "$QBT_HOST" '.fields |= map(if .name == "host" then .value = $host else . end)' <<<"$client" |
        api -X PUT --data @- "$base/downloadclient/$id?forceSave=true" >/dev/null
      log "download client $id: host $host -> $QBT_HOST"
    else
      log "download client $id ($host) left as is"
    fi
  done < <(jq -c '.[]' <<<"$clients")
fi
