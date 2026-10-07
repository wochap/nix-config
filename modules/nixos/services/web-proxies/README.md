# Web proxies

Declarative nginx vhosts for local services, set through `_custom.services.web-proxies.<name>`.

- Every enabled proxy is served on this host only, at `https://<subdomain>.wochap.local` (`127.0.1.1`). It uses the self-signed `wochap-ssc` certificate.
- With `expose.enable = true`, the proxy is also served on the LAN at `https://<subdomain>.<web-gate.domain>`. nginx listens on `0.0.0.0:443` and uses a Let's Encrypt wildcard certificate.
- With `expose.gate = true`, the LAN vhost sits behind a cookie gate. A visitor enters Basic Auth once, then gets a cookie. `sudo web-gate` rotates the password and prints it. Leave the gate off for services used from mobile or TV apps: those apps cannot complete the login. They rely on the service's own login instead.

## LAN setup (Cloudflare)

Host config, as on gdesktop:

```nix
_custom.services.web-gate.domain = "gdesktop.geanmar.com";
_custom.services.web-gate.acme.credentialSecret.sopsFile = ../../secrets-sops/personal.yaml;
_custom.services.web-gate.acme.credentialSecret.sopsKey = "personal-cloudflare-dns-api-token";
_custom.services.web-gate.ddns.enable = true;
_custom.services.web-gate.ddns.zone = "geanmar.com";
_custom.services.web-proxies.jellyfin.expose.enable = true;
```

Each host needs its own domain, because a wildcard certificate covers one label only. gdesktop uses `gdesktop.geanmar.com`, and glegion uses `glegion.geanmar.com`.

For another DNS provider, set `web-gate.acme.dnsProvider` and `web-gate.acme.credentialSecret.variable` to the lego provider name and its token variable.

Name resolution comes from a public DNS record that points at this host's LAN IP, so no LAN DNS server is needed. The certificate comes from the DNS-01 challenge, so no port is open to the internet.

### Cloudflare API token

ACME and DDNS use one API token. All hosts can share it, because every host's record lives in the same zone.

1. Sign in to dash.cloudflare.com. Open the profile menu (top right) › Profile › API Tokens.
2. Select **Create Token**. Next to the **Edit zone DNS** template, select **Use template**.
3. Set the fields:
   - Token name: for example `web-gate-dns`.
   - Permissions: keep `Zone` › `DNS` › `Edit` from the template. Add a second row, `Zone` › `Zone` › `Read`. lego and `web-gate-lan` look up the zone ID by name with this permission.
   - Zone Resources: `Include` › `Specific zone` › `geanmar.com`.
   - Client IP Address Filtering: leave empty. A laptop changes its public IP.
   - TTL: leave empty, or set an end date and rotate the token before then.
4. Select **Continue to summary** › **Create Token**. Copy the token: Cloudflare shows it only once.
5. Optional check:

   ```sh
   curl -s -H "Authorization: Bearer <token>" https://api.cloudflare.com/client/v4/user/tokens/verify
   # "status": "active"
   ```

A token cannot be limited to some records. It can edit every DNS record in the zone, so treat it like a password. To revoke it, delete it on the same API Tokens page.

### Host setup

1. Store the token in `web-gate.acme.credentialSecret.sopsFile` under the key `web-gate.acme.credentialSecret.sopsKey`:

   ```sh
   sops secrets-sops/personal.yaml
   # personal-cloudflare-dns-api-token: <token>
   ```

2. Rebuild and switch. Then check that the certificate was issued:

   ```sh
   systemctl status acme-order-renew-gdesktop.geanmar.com
   ls /var/lib/acme/gdesktop.geanmar.com
   ```

The NixOS ACME module renews the certificate on a timer.

Without `ddns.enable`, create the record by hand instead: in dash.cloudflare.com, go to the zone › DNS › Records › Add record, with Type `A`, Name `*.gdesktop` (the domain without the zone), the host's fixed LAN IP, and Proxy status **DNS only** (grey cloud). Cloudflare cannot proxy a private IP.

## DDNS and trusted networks

`web-gate.ddns.enable` keeps the `*.<domain>` A record (TTL `ddns.ttl`, default 60 s) pointed at the host's current LAN IPv4. The `web-gate-lan` service does the update. It runs:
- on every NetworkManager `up`, `down`, `dhcp4-change` and `connectivity-change` event,
- once an hour,
- on demand with `sudo systemctl start web-gate-lan`.

`web-gate.trustedConnections` lists the NetworkManager connection names or UUIDs (`nmcli connection show`) on which port 443 opens. On any other network the LAN vhosts stay unreachable, and the DNS record is left unchanged. The `web-gate-lan` chain in the iptables firewall holds the open ports. With the default `null`, port 443 is open on every interface, which suits a host that never moves.

A laptop such as glegion lists its home and friends' networks. On those networks, other devices reach `https://<name>.glegion.geanmar.com` with a valid certificate and no setup on their side. This does not work:
- without internet, because the name comes from public DNS,
- behind a router with DNS rebind protection that you cannot change,
- on networks with client isolation (guest Wi-Fi, hotels).

For those cases, use `http://<laptop-ip>:<port>` or Tailscale.

To see the current state, run `sudo iptables -L web-gate-lan -n` and `journalctl -u web-gate-lan`.

## Troubleshooting

- **The name does not resolve on a LAN device.** Some routers have DNS rebind protection, which drops public answers that point at private IPs. Whitelist `gdesktop.geanmar.com` in the router. To check, run `dig +short jellyfin.gdesktop.geanmar.com` against the router and against `1.1.1.1`, and compare the answers.
- **Certificate renewal fails.** Read `journalctl -u acme-order-renew-gdesktop.geanmar.com`. Usually the token has expired, or its scope does not cover the zone.
- **Containers call a LAN name.** This works: the containers resolve it through the host, and the certificate is publicly trusted. Prefer container names for calls between containers anyway, for example `http://media-jellyfin:8096`.
