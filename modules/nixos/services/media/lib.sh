# Shared helpers for the media bootstrap scripts. Prepended to each script by
# mkScript in common.nix; LOG_TAG, WAIT_TRIES and WAIT_DELAY come from there.
#
# Secrets never go on a command line: keys and passwords are read from files
# into variables and handed to curl and jq through process substitution.

log() {
  echo "$LOG_TAG: $*"
}

warn() {
  echo "$LOG_TAG: warning: $*" >&2
}

die() {
  echo "$LOG_TAG: $*" >&2
  exit 1
}

# wait_until DESCRIPTION COMMAND...: retries COMMAND until it succeeds.
wait_until() {
  local what=$1 i
  shift
  for ((i = 1; i <= WAIT_TRIES; i++)); do
    if "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$WAIT_DELAY"
  done
  die "$what did not answer after $((WAIT_TRIES * WAIT_DELAY))s"
}

# read_secret FILE: prints the file without trailing newlines.
read_secret() {
  local value
  value=$(<"$1")
  printf '%s' "$value"
}

# servarr_ensure_login BASE_URL: Forms login for ADMIN_USER through the
# documented host config API (GET/PUT <api>/config/host), only while the app
# has no user. Needs an `api` function that adds the API key.
servarr_ensure_login() {
  local base=$1 host password
  host=$(api "$base/config/host")
  if [ -n "$(jq -r '.username // ""' <<<"$host")" ]; then
    log "login present, left as is"
    return 0
  fi
  password=$(read_secret "$ADMIN_PASSWORD_FILE")
  jq --arg user "$ADMIN_USER" --rawfile pw <(printf '%s' "$password") '
    . + {
      authenticationMethod: "forms",
      authenticationRequired: "enabled",
      username: $user,
      password: $pw,
      passwordConfirmation: $pw
    }' <<<"$host" |
    api -X PUT --data @- "$base/config/host/$(jq -r .id <<<"$host")" >/dev/null
  log "login set: Forms, user $ADMIN_USER"
}
