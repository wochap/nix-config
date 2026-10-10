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
   # Ubuntu 26.04 (kernel 7.0) fails kexec_file_load ("Address not available"), force the legacy syscall
   nix run github:nix-community/nixos-anywhere -- --flake .#gvps --build-on local \
     --kexec-extra-flags "--kexec-syscall" ubuntu@<ip>
   ```
6. Log in:
   ```sh
   ssh-keygen -R <ip>
   ssh gean@<ip>
   ```

## Headscale

See [modules/nixos/services/headscale/README.md](../../modules/nixos/services/headscale/README.md).

## Update

```sh
nixos-rebuild switch --flake .#gvps --target-host gean@<ip> --use-remote-sudo
```

## Notes

- SSH is key-only, no root login. Fallback is the OVH KVM console with `gean`'s password.
- IPv6 may need static config in `networking.interfaces.ens3.ipv6`.
