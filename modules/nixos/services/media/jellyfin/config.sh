# media-jellyfin-config
#
# Uses Jellyfin's public API (OpenAPI at /api-docs/openapi.json):
#   - while the startup wizard is not completed: /Startup/User creates the
#     admin ADMIN_USER, /Startup/Complete ends the wizard
#   - as that admin (/Users/AuthenticateByName): adds the libraries in
#     JF_LIBRARIES ("name collectionType path" per line) whose folder no
#     library uses yet, and sets JF_HWACCEL (vaapi with JF_VAAPI_DEVICE, or
#     nvenc) while hardware acceleration is still "none"
# When the admin login does not work (the server was set up by hand with
# another login), libraries and transcoding are left alone.

client='MediaBrowser Client="nixos-media-config", Device="nixos", DeviceId="media-jellyfin-config", Version="1"'
token=""

jf() {
  local auth=$client
  [ -z "$token" ] || auth="$client, Token=\"$token\""
  curl -fsS -H @<(printf 'Authorization: %s\n' "$auth") \
    -H "Content-Type: application/json" "$@"
}

logout() {
  if [ -n "$token" ]; then
    jf -X POST -o /dev/null "$JF_URL/Sessions/Logout" || true
  fi
}
trap logout EXIT

wait_until "Jellyfin at $JF_URL" jf -o /dev/null "$JF_URL/System/Info/Public"

password=$(read_secret "$ADMIN_PASSWORD_FILE")

# Startup wizard
if jf "$JF_URL/System/Info/Public" | jq -e '.StartupWizardCompleted' >/dev/null; then
  log "startup wizard completed before, admin left as is"
else
  # GET first, as the wizard does: it makes sure the initial user exists.
  jf -o /dev/null "$JF_URL/Startup/User"
  jq -n --arg user "$ADMIN_USER" --rawfile pw <(printf '%s' "$password") \
    '{Name: $user, Password: $pw}' |
    jf -X POST --data @- "$JF_URL/Startup/User" >/dev/null
  jf -X POST -o /dev/null "$JF_URL/Startup/Complete"
  log "startup wizard completed, admin $ADMIN_USER"
fi

# Admin session
auth=$(jq -n --arg user "$ADMIN_USER" --rawfile pw <(printf '%s' "$password") \
  '{Username: $user, Pw: $pw}' |
  jf -X POST --data @- "$JF_URL/Users/AuthenticateByName" 2>/dev/null) || auth=""
if [ -n "$auth" ]; then
  token=$(jq -r '.AccessToken // ""' <<<"$auth")
fi
if [ -z "$token" ]; then
  log "admin login $ADMIN_USER does not work; libraries and transcoding left to the dashboard"
  exit 0
fi

# Libraries
folders=$(jf "$JF_URL/Library/VirtualFolders")
while read -r lib_name type path; do
  [ -n "$lib_name" ] || continue
  if jq -e --arg p "$path" 'any(.[]; any(.Locations[]?; rtrimstr("/") == $p))' <<<"$folders" >/dev/null; then
    log "library for $path present"
    continue
  fi
  query=$(jq -rn --arg n "$lib_name" --arg t "$type" --arg p "$path" \
    '"name=\($n | @uri)&collectionType=\($t | @uri)&paths=\($p | @uri)&refreshLibrary=true"')
  jf -X POST -o /dev/null --data '{"LibraryOptions": {}}' "$JF_URL/Library/VirtualFolders?$query"
  log "added library $lib_name ($type, $path)"
done <<<"$JF_LIBRARIES"

# Hardware transcoding
if [ -n "$JF_HWACCEL" ]; then
  encoding=$(jf "$JF_URL/System/Configuration/encoding")
  current=$(jq -r '.HardwareAccelerationType // "none"' <<<"$encoding")
  if [ "$current" != none ]; then
    log "hardware acceleration $current left as is"
  else
    jq --arg type "$JF_HWACCEL" --arg device "$JF_VAAPI_DEVICE" '
      .HardwareAccelerationType = $type
      | .EnableHardwareEncoding = true
      | if $type == "vaapi" then .VaapiDevice = $device else . end' <<<"$encoding" |
      jf -X POST --data @- "$JF_URL/System/Configuration/encoding" >/dev/null
    log "hardware acceleration $JF_HWACCEL on"
  fi
fi
