# media-qbittorrent-config
#
# Configures qBittorrent through the documented WebUI API (/api/v2):
#   - auth bypass for the media network (QBT_SUBNET); other subnets stay
#   - the admin login, once (see below)
#   - default save path QBT_SAVE_PATH with Automatic Torrent Management,
#     while the save path is still the image's /config/Downloads
#   - the categories in QBT_CATEGORIES ("name path" per line), when missing
#
# Access: host requests through the published port arrive from the media
# gateway, which the image's default whitelist (10.0.0.0/8) bypasses. When the
# bypass is off, the script logs in as ADMIN_USER.
#
# The API cannot tell whether a password was ever set. The login is set once,
# when the shared login does not work yet and QBT_MARKER does not exist; the
# marker then keeps a password changed later in the UI.

jar=$(mktemp)
trap 'rm -f "$jar"' EXIT

qbt() {
  curl -fsS -b "$jar" -c "$jar" -H "Referer: $QBT_URL" "$@"
}

password=$(read_secret "$ADMIN_PASSWORD_FILE")

# login: true when the shared login works.
login() {
  local out
  out=$(qbt --data-urlencode "username=$ADMIN_USER" \
    --data-urlencode "password@"<(printf '%s' "$password") \
    "$QBT_URL/api/v2/auth/login" 2>/dev/null) || return 1
  [ "$out" = "Ok." ]
}

# The WebUI answers 403 without a session; any HTTP answer means it is up.
wait_until "qBittorrent at $QBT_URL" curl -sS -o /dev/null "$QBT_URL/api/v2/app/version"

if qbt -o /dev/null "$QBT_URL/api/v2/app/version" 2>/dev/null; then
  log "WebUI API reachable through the subnet bypass"
elif login; then
  log "logged in as $ADMIN_USER"
else
  die "WebUI API refused: no subnet bypass and the shared login does not work"
fi

prefs=$(qbt "$QBT_URL/api/v2/app/preferences")

# set_prefs JSON: the JSON travels through a file descriptor.
set_prefs() {
  qbt --data-urlencode "json@"<(printf '%s' "$1") "$QBT_URL/api/v2/app/setPreferences" >/dev/null
}

# Auth bypass for the media network
if jq -e --arg s "$QBT_SUBNET" '
  .bypass_auth_subnet_whitelist_enabled
  and (.bypass_auth_subnet_whitelist | split("\n") | map(gsub("^\\s+|[\\s,]+$"; "")) | index($s))' \
  <<<"$prefs" >/dev/null; then
  log "auth bypass for $QBT_SUBNET present"
else
  set_prefs "$(jq -c --arg s "$QBT_SUBNET" '
    (.bypass_auth_subnet_whitelist | split("\n") | map(select(test("\\S")))) as $list
    | {
        bypass_auth_subnet_whitelist_enabled: true,
        bypass_auth_subnet_whitelist: (
          if ($list | map(gsub("^\\s+|[\\s,]+$"; "")) | index($s)) then $list else $list + [$s] end
          | join("\n"))
      }' <<<"$prefs")"
  log "auth bypass for $QBT_SUBNET enabled"
fi

# Admin login
if [ -e "$QBT_MARKER" ]; then
  log "login set before, left as is"
elif login; then
  log "login $ADMIN_USER works"
  touch "$QBT_MARKER"
else
  set_prefs "$(jq -nc --arg user "$ADMIN_USER" --rawfile pw <(printf '%s' "$password") \
    '{web_ui_username: $user, web_ui_password: $pw}')"
  touch "$QBT_MARKER"
  log "login set: user $ADMIN_USER"
fi

# Default save path
save_path=$(jq -r .save_path <<<"$prefs")
case "$save_path" in
  "$QBT_SAVE_PATH" | "$QBT_SAVE_PATH"/*)
    log "default save path $save_path left as is"
    ;;
  *)
    set_prefs "$(jq -nc --arg p "$QBT_SAVE_PATH" '{save_path: $p, auto_tmm_enabled: true}')"
    log "default save path $save_path -> $QBT_SAVE_PATH, automatic torrent management on"
    ;;
esac

# Categories
categories=$(qbt "$QBT_URL/api/v2/torrents/categories")
while read -r category path; do
  [ -n "$category" ] || continue
  if jq -e --arg c "$category" 'has($c)' <<<"$categories" >/dev/null; then
    log "category $category present"
  else
    qbt --data-urlencode "category=$category" --data-urlencode "savePath=$path" \
      "$QBT_URL/api/v2/torrents/createCategory" >/dev/null
    log "added category $category ($path)"
  fi
done <<<"$QBT_CATEGORIES"
