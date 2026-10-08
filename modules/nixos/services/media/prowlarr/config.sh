# media-prowlarr-config
#
# Sets the admin login while Prowlarr has none, and registers Sonarr, Radarr
# and LazyLibrarian as applications with Full Sync, so Prowlarr pushes its
# indexers to them. An app that already exists is
# left as is. PROWLARR_* and the per-app variables come from the Nix module;
# an empty *_URL means the app is disabled.

api_key=$(read_secret "$PROWLARR_API_KEY_FILE")

api() {
  curl -fsS -H @<(printf 'X-Api-Key: %s\n' "$api_key") \
    -H "Content-Type: application/json" "$@"
}

wait_until "Prowlarr at $PROWLARR_URL" api -o /dev/null "$PROWLARR_URL/api/v1/system/status"

servarr_ensure_login "$PROWLARR_URL/api/v1"

apps=$(api "$PROWLARR_URL/api/v1/applications")
schema=$(api "$PROWLARR_URL/api/v1/applications/schema")

# ensure_app IMPLEMENTATION BASE_URL KEY
ensure_app() {
  local impl=$1 base=$2 key=$3
  if jq -e --arg impl "$impl" 'any(.[]; .implementation == $impl)' <<<"$apps" >/dev/null; then
    log "$impl app present, left as is"
    return 0
  fi
  if [ -z "$key" ]; then
    warn "$impl has no API key yet, skipped"
    return 0
  fi
  jq --arg impl "$impl" --arg self "$PROWLARR_SELF_URL" --arg base "$base" \
    --rawfile key <(printf '%s' "$key") '
    first(.[] | select(.implementation == $impl))
    | . + {name: $impl, enable: true, syncLevel: "fullSync"}
    | .fields |= map(
        if .name == "prowlarrUrl" then .value = $self
        elif .name == "baseUrl" then .value = $base
        elif .name == "apiKey" then .value = $key
        else . end)' <<<"$schema" |
    api -X POST --data @- "$PROWLARR_URL/api/v1/applications?forceSave=true" >/dev/null ||
    return 1
  log "added $impl app ($base, Full Sync)"
}

if [ -n "$SONARR_URL" ]; then
  ensure_app Sonarr "$SONARR_URL" "$(read_secret "$SONARR_API_KEY_FILE")"
fi
if [ -n "$RADARR_URL" ]; then
  ensure_app Radarr "$RADARR_URL" "$(read_secret "$RADARR_API_KEY_FILE")"
fi
if [ -n "$LAZYLIBRARIAN_URL" ]; then
  # A copy of the key LazyLibrarian generated in its UI (no stable way to
  # preset it). Prowlarr tests the connection on save and answers 400 until
  # LazyLibrarian's API is on with that key, so this step only warns.
  ensure_app LazyLibrarian "$LAZYLIBRARIAN_URL" "$(read_secret "$LAZYLIBRARIAN_API_KEY_FILE")" ||
    warn "LazyLibrarian app not added: turn on its API and store its key (see lazylibrarian/README.md), then restart media-prowlarr-config"
fi
