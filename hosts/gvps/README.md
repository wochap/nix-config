# gvps

OVH VPS (Model 1: 2 vCore, 4 GB, 40 GB NVMe), installed with nixos-anywhere.

## Install

1. Order the VPS with any image (Ubuntu used). Grab the `ubuntu` password from the OVH email.
2. First login forces a password change, which needs a TTY:
   ```sh
   ssh -t ubuntu@<ip>
   ssh-copy-id ubuntu@<ip>
   ```
3. Sanity check. Disk must match `disk-configuration.nix` (`/dev/sda`), RAM >= 1 GB, passwordless sudo:
   ```sh
   ssh ubuntu@<ip> 'lsblk; free -h; sudo -n true && echo sudo-ok'
   ```
4. Cloudflare DNS (before install, so Caddy gets its cert on first boot): `A hs <ip>`, **DNS only** (grey cloud; the proxy breaks Tailscale and DERP). No record for `tail.` (MagicDNS only), no AAAA until IPv6 works.
5. Build locally, then install (wipes the disk):
   ```sh
   nix build .#nixosConfigurations.gvps.config.system.build.toplevel --no-link
   nix run github:nix-community/nixos-anywhere -- --flake .#gvps --build-on local ubuntu@<ip>
   ```
6. Log in:
   ```sh
   ssh-keygen -R <ip>
   ssh gean@<ip>
   ```

## Headscale

```sh
curl -I https://hs.geanmar.com/health   # 200 once Caddy has the cert
sudo headscale users create gean
sudo headscale preauthkeys create --user gean
# on each client
sudo tailscale up --login-server https://hs.geanmar.com --authkey <key>
```

## Update

```sh
nixos-rebuild switch --flake .#gvps --target-host gean@<ip> --use-remote-sudo
```

## Notes

- SSH is key-only, no root login. Fallback is the OVH KVM console with `gean`'s password.
- IPv6 may need static config in `networking.interfaces.ens3.ipv6`.
