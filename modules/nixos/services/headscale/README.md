# headscale

Self-hosted Tailscale control server behind Caddy (`https://<domain>`), with built-in DERP (STUN on UDP 3478). Runs on gvps.

## DNS

Cloudflare: `A hs <vps-ip>`, **DNS only** (the proxy breaks Tailscale/DERP). No record for `baseDomain` (MagicDNS only).

## Setup

```sh
curl -I https://hs.geanmar.com/health   # 200 once Caddy has the cert
sudo headscale users create gean # on server
```

Join gvps itself, then set `nameservers` to its `tailscale ip -4` (AdGuard, pushed to every client). Until then clients can't resolve anything while connected.

```sh
sudo tailscale up --login-server https://hs.geanmar.com --authkey <key> --accept-dns=false
```

## Add a client

NixOS host (`_custom.services.tailscale`, needs `loginServer`):

```sh
sudo headscale users list                        # on gvps, note the ID
sudo headscale preauthkeys create --user <id>    # 1h, single use by default
sudo systemctl start tailscaled                  # if startOnBoot = false
tailscale up --login-server https://hs.geanmar.com --authkey <key>
```

Android (official Tailscale app, no Tailscale account): Settings → Accounts → ⋮ → **Use an alternate server** → `https://hs.geanmar.com`. The browser shows a register command, run it on gvps:

```sh
sudo headscale nodes register --user gean --key <key>
```

If DNS fails on Android, set Private DNS to Off/Automatic.

## Manage

```sh
sudo headscale nodes list
sudo headscale nodes delete -i <id>
```

## Troubleshooting

**Pages don't load ("server not found") while connected:** clients send all DNS to `nameservers`, so gvps must be in the tailnet and `nameservers` must match its IP.

```sh
tailscale ip -4                 # on gvps; NeedsLogin = not joined, see Setup
dig @<that-ip> google.com       # from a client, should resolve
```
