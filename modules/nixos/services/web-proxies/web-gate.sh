# web-gate [rotate] [--quiet] [--no-reload]
#
# Rotates the LAN gate: new Basic Auth password + new cookie token, then
# reloads nginx so every previously issued cookie stops working.
# GATE_STATE_DIR, GATE_USER and GATE_URLS come from the Nix module.

quiet=0
reload=1
for arg in "$@"; do
  case "$arg" in
    rotate) ;;
    --quiet) quiet=1 ;;
    --no-reload) reload=0 ;;
    -h | --help)
      echo "usage: web-gate [rotate] [--quiet] [--no-reload]"
      exit 0
      ;;
    *)
      echo "web-gate: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

umask 027
install -d -m 0750 -o root -g nginx "$GATE_STATE_DIR"

pass=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 12)
token=$(openssl rand -hex 32)

tmp_token=$(mktemp "$GATE_STATE_DIR/.token.XXXXXX")
tmp_htpasswd=$(mktemp "$GATE_STATE_DIR/.htpasswd.XXXXXX")
trap 'rm -f "$tmp_token" "$tmp_htpasswd"' EXIT

# shellcheck disable=SC2016 # literal nginx variable
printf 'set $gate_token "%s";\n' "$token" >"$tmp_token"
printf '%s:%s\n' "$GATE_USER" "$(openssl passwd -apr1 "$pass")" >"$tmp_htpasswd"
chgrp nginx "$tmp_token" "$tmp_htpasswd"
chmod 0640 "$tmp_token" "$tmp_htpasswd"
mv -f "$tmp_token" "$GATE_STATE_DIR/token.conf"
mv -f "$tmp_htpasswd" "$GATE_STATE_DIR/htpasswd"
trap - EXIT

if [ "$reload" -eq 1 ]; then
  systemctl reload nginx.service
fi

if [ "$quiet" -eq 0 ]; then
  echo "user:     $GATE_USER"
  echo "password: $pass"
  for url in $GATE_URLS; do
    echo "url:      $url"
  done
fi
