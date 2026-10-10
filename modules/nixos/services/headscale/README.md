# headscale

Self-hosted Tailscale control server behind Caddy (`https://<domain>`), with built-in DERP (STUN on UDP 3478). Runs on gvps.

## DNS

Cloudflare: `A hs <vps-ip>`, **DNS only** (the proxy breaks Tailscale/DERP). No record for `baseDomain` (MagicDNS only).

## Setup

```sh
curl -I https://hs.geanmar.com/health   # 200 once Caddy has the cert
sudo headscale users create gean # on server
```

Register gvps **first**: it must get `100.64.0.1`, the AdGuard nameserver pushed to clients (`nameservers` option).

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
