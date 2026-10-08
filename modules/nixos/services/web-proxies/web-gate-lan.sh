# web-gate-lan [firewall|sync]
#
# Keeps LAN exposure in line with the active NetworkManager connections.
#   firewall: opens LAN_PORT only on devices of trusted connections.
#   sync:     firewall, then points the Cloudflare A record at this host's LAN
#             IP (when DDNS is enabled).
# LAN_* and DDNS_* come from the Nix module. DDNS_RECORDS is space separated.
# LAN_TRUSTED holds one connection name or UUID per line, or "*" to trust
# every connection.

mode=${1:-sync}
case "$mode" in
  firewall | sync) ;;
  -h | --help)
    echo "usage: web-gate-lan [firewall|sync]"
    exit 0
    ;;
  *)
    echo "web-gate-lan: unknown argument: $mode" >&2
    exit 2
    ;;
esac

is_trusted() {
  local uuid=$1 name=$2 entry
  [ "$LAN_TRUSTED" = "*" ] && return 0
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    if [ "$entry" = "$uuid" ] || [ "$entry" = "$name" ]; then
      return 0
    fi
  done <<<"$LAN_TRUSTED"
  return 1
}

# Devices of active ethernet/wifi connections that are trusted, one per line.
trusted_devices() {
  local uuid dev type name
  # UUID, DEVICE and TYPE never contain ':', so terse output splits cleanly.
  nmcli -t -f UUID,DEVICE,TYPE connection show --active 2>/dev/null |
    while IFS=: read -r uuid dev type; do
      case "$type" in
        802-3-ethernet | 802-11-wireless) ;;
        *) continue ;;
      esac
      name=$(nmcli -g connection.id connection show "$uuid" 2>/dev/null) || continue
      if is_trusted "$uuid" "$name"; then
        echo "$dev"
      fi
    done
}

mapfile -t devices < <(trusted_devices)

for ipt in iptables ip6tables; do
  "$ipt" -w -N "$LAN_CHAIN" 2>/dev/null || true
  "$ipt" -w -F "$LAN_CHAIN"
  for dev in "${devices[@]}"; do
    "$ipt" -w -A "$LAN_CHAIN" -i "$dev" -p tcp --dport "$LAN_PORT" -j ACCEPT
  done
done
echo "web-gate-lan: port $LAN_PORT open on: ${devices[*]:-none}"

[ "$mode" = sync ] || exit 0
[ "$DDNS_ENABLE" = 1 ] || exit 0

if [ "${#devices[@]}" -eq 0 ]; then
  echo "web-gate-lan: no trusted connection, DNS record left unchanged"
  exit 0
fi

# Prefer the device that carries the default route.
route_dev=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
dev=${devices[0]}
for d in "${devices[@]}"; do
  if [ "$d" = "$route_dev" ]; then
    dev=$d
  fi
done

addr=$(ip -4 -o addr show dev "$dev" scope global | awk '{ split($4, a, "/"); print a[1]; exit }')
if [ -z "$addr" ]; then
  echo "web-gate-lan: $dev has no IPv4 address yet"
  exit 0
fi

api() {
  # The token goes through a file descriptor so it never shows in ps.
  curl -fsS --retry 3 --retry-connrefused \
    -H @<(printf 'Authorization: Bearer %s\n' "$(cat "$DDNS_TOKEN_FILE")") \
    -H "Content-Type: application/json" \
    "$@"
}

base=https://api.cloudflare.com/client/v4
zone_id=$(api "$base/zones?name=$DDNS_ZONE" | jq -r '.result[0].id // empty')
if [ -z "$zone_id" ]; then
  echo "web-gate-lan: zone $DDNS_ZONE not found or token lacks access" >&2
  exit 1
fi

update_record() {
  local name=$1 record record_id current body
  record=$(api "$base/zones/$zone_id/dns_records?type=A&name=${name//\*/%2A}")
  record_id=$(jq -r '.result[0].id // empty' <<<"$record")
  current=$(jq -r '.result[0].content // empty' <<<"$record")

  if [ "$current" = "$addr" ]; then
    echo "web-gate-lan: $name already points at $addr"
    return 0
  fi

  body=$(jq -n --arg name "$name" --arg addr "$addr" --argjson ttl "$DDNS_TTL" \
    '{type: "A", name: $name, content: $addr, ttl: $ttl, proxied: false}')

  if [ -n "$record_id" ]; then
    api -X PUT "$base/zones/$zone_id/dns_records/$record_id" --data "$body" >/dev/null
  else
    api -X POST "$base/zones/$zone_id/dns_records" --data "$body" >/dev/null
  fi
  echo "web-gate-lan: $name now points at $addr (was ${current:-unset})"
}

# read -a splits without glob expansion, so "*.<domain>" stays literal.
read -r -a records <<<"$DDNS_RECORDS"
for name in "${records[@]}"; do
  update_record "$name"
done
