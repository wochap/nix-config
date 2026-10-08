# media-seerr-config
#
# Uses Seerr's documented API (seerr-api.yml, served at /api-docs). The API key
# comes from SOPS through Seerr's documented API_KEY env var and acts as the
# admin account, so every step after the sign-in works whatever the admin's
# password.
#   - no admin and not initialized: signs in with the shared Jellyfin admin
#     (/auth/jellyfin, server SEERR_JELLYFIN_HOST:8096), which creates the admin
#   - syncs the Jellyfin libraries and, while none is enabled, enables the
#     ones named in SEERR_LIBRARIES (one per line)
#   - Jellyfin External URL and Application URL, while empty
#   - default Radarr and Sonarr servers, while Seerr has none of that kind;
#     quality profile SEERR_PROFILE, else the first one
#   - finishes the setup wizard (/settings/initialize) when this run did the
#     sign-in; a wizard started by hand is left for the user to finish
# Users, permissions and approval rules stay manual. An empty RADARR_URL or
# SONARR_URL means that app is disabled.

api_key=$(read_secret "$SEERR_API_KEY_FILE")

seerr() {
  curl -fsS -H @<(printf 'X-Api-Key: %s\n' "$api_key") \
    -H "Content-Type: application/json" "$@"
}

wait_until "Seerr at $SEERR_URL" curl -fsS -o /dev/null "$SEERR_URL/api/v1/status"

initialized=$(curl -fsS "$SEERR_URL/api/v1/settings/public" | jq -r '.initialized')
signed_in=0

# Admin account
if seerr -o /dev/null "$SEERR_URL/api/v1/settings/main" 2>/dev/null; then
  log "admin account present"
elif [ "$initialized" = true ]; then
  warn "Seerr is initialized but the API key has no admin account; nothing to do"
  exit 0
else
  password=$(read_secret "$ADMIN_PASSWORD_FILE")
  # sign_in [HOST]: with HOST, also stores the Jellyfin server (first run).
  sign_in() {
    jq -n --arg user "$ADMIN_USER" --rawfile pw <(printf '%s' "$password") \
      --arg host "${1:-}" '
      {username: $user, password: $pw, serverType: 2}
      + if $host == "" then {} else
          {hostname: $host, port: 8096, useSsl: false, urlBase: ""}
        end' |
      curl -fsS -o /dev/null -H "Content-Type: application/json" --data @- \
        "$SEERR_URL/api/v1/auth/jellyfin"
  }
  wait_until "Jellyfin at $SEERR_JELLYFIN_CHECK_URL" curl -fsS -o /dev/null "$SEERR_JELLYFIN_CHECK_URL"
  # The server is only accepted while Seerr has none stored yet.
  if sign_in "$SEERR_JELLYFIN_HOST" 2>/dev/null || sign_in 2>/dev/null; then
    signed_in=1
    log "signed in with Jellyfin admin $ADMIN_USER"
  else
    log "Jellyfin sign-in as $ADMIN_USER failed; finish the Seerr wizard by hand, then: systemctl restart media-seerr-config"
    exit 0
  fi
fi

# Libraries
libraries=$(seerr -X POST "$SEERR_URL/api/v1/settings/jellyfin/library/sync")
if jq -e 'any(.[]; .enabled)' <<<"$libraries" >/dev/null; then
  log "library selection present, left as is"
else
  while IFS= read -r wanted; do
    [ -n "$wanted" ] || continue
    id=$(jq -r --arg n "$wanted" 'first(.[] | select(.name == $n) | .id) // ""' <<<"$libraries")
    if [ -z "$id" ]; then
      warn "no Jellyfin library named $wanted"
      continue
    fi
    seerr -X PUT --data '{"enabled": true}' -o /dev/null "$SEERR_URL/api/v1/settings/jellyfin/library/$id"
    log "enabled library $wanted"
  done <<<"$SEERR_LIBRARIES"
fi

# URLs shown to users
if [ -n "$(seerr "$SEERR_URL/api/v1/settings/jellyfin" | jq -r '.externalHostname // ""')" ]; then
  log "Jellyfin External URL present, left as is"
else
  jq -n --arg url "$SEERR_JELLYFIN_URL" '{externalHostname: $url}' |
    seerr -X POST --data @- -o /dev/null "$SEERR_URL/api/v1/settings/jellyfin"
  log "Jellyfin External URL $SEERR_JELLYFIN_URL"
fi
if [ -n "$(seerr "$SEERR_URL/api/v1/settings/main" | jq -r '.applicationUrl // ""')" ]; then
  log "Application URL present, left as is"
else
  jq -n --arg url "$SEERR_APP_URL" '{applicationUrl: $url}' |
    seerr -X POST --data @- -o /dev/null "$SEERR_URL/api/v1/settings/main"
  log "Application URL $SEERR_APP_URL"
fi

# ensure_server KIND LOCAL_URL KEY_FILE HOST PORT ROOT EXTRA_JSON
ensure_server() {
  local kind=$1 url=$2 key_file=$3 host=$4 port=$5 root=$6 extra=$7 key profiles name
  if seerr "$SEERR_URL/api/v1/settings/$kind" | jq -e 'length > 0' >/dev/null; then
    log "$kind server present, left as is"
    return 0
  fi
  key=$(read_secret "$key_file")
  wait_until "$kind at $url" curl -fsS -o /dev/null \
    -H @<(printf 'X-Api-Key: %s\n' "$key") "$url/api/v3/system/status"
  profiles=$(curl -fsS -H @<(printf 'X-Api-Key: %s\n' "$key") "$url/api/v3/qualityprofile")
  name=${kind^}
  jq --arg profile "$SEERR_PROFILE" --arg name "$name" --arg host "$host" \
    --argjson port "$port" --arg root "$root" --argjson extra "$extra" \
    --rawfile key <(printf '%s' "$key") '
    (first(.[] | select(.name == $profile)) // .[0]) as $p
    | if $p == null then error("no quality profile") else . end
    | {
        name: $name, hostname: $host, port: $port, apiKey: $key,
        useSsl: false, baseUrl: "",
        activeProfileId: $p.id, activeProfileName: $p.name,
        activeDirectory: $root, tags: [],
        is4k: false, isDefault: true, externalUrl: "",
        syncEnabled: true, preventSearch: false, tagRequests: false,
        overrideRule: []
      }
      + ($extra | with_entries(
          if .value == "@profileId" then .value = $p.id
          elif .value == "@profileName" then .value = $p.name
          else . end))' <<<"$profiles" |
    seerr -X POST --data @- "$SEERR_URL/api/v1/settings/$kind" >/dev/null
  log "added $name ($host:$port, root $root)"
}

if [ -n "$RADARR_URL" ]; then
  ensure_server radarr "$RADARR_URL" "$RADARR_API_KEY_FILE" "$RADARR_HOST" 7878 \
    /data/media/movies '{"minimumAvailability": "released"}'
fi
if [ -n "$SONARR_URL" ]; then
  ensure_server sonarr "$SONARR_URL" "$SONARR_API_KEY_FILE" "$SONARR_HOST" 8989 \
    /data/media/series '{
      "seriesType": "standard", "animeSeriesType": "anime",
      "activeAnimeProfileId": "@profileId", "activeAnimeProfileName": "@profileName",
      "activeAnimeDirectory": "/data/media/series", "animeTags": [],
      "enableSeasonFolders": true, "monitorNewItems": "all"
    }'
fi

# Setup wizard
if [ "$signed_in" = 1 ] && [ "$initialized" != true ]; then
  seerr -X POST -o /dev/null "$SEERR_URL/api/v1/settings/initialize"
  log "setup wizard finished"
fi
