# Tailscale

## Pause / resume

```bash
tailscale down   # disconnect, stays logged in, tailscaled keeps running
tailscale up     # reconnect (if it complains: tailscale up --login-server=<loginServer>)
```

`sudo systemctl stop tailscaled` for a full stop (restarts on boot).

## LAN + tailnet

Both work at the same time. Tailscale only routes `100.64.0.0/10` and accepted subnet routes; LAN traffic is untouched.

Can break LAN access:

- Exit node: add `--exit-node-allow-lan-access`.
- `--accept-routes` with a subnet overlapping the LAN.
- MagicDNS with headscale `override_local_dns`: LAN-only hostnames (e.g. `router.lan`) may stop resolving. Disable it or add split DNS for the LAN domain.

## Lost / stolen device

Cut it off the tailnet from any other machine (on gvps; KVM console if tailnet SSH is the only way in):

```bash
ssh gvps
sudo headscale nodes list                                # find the device's ID
sudo headscale nodes expire -i <id>                      # kills access immediately
sudo headscale nodes delete -i <id>                      # also drops its routes / exit node
sudo headscale preauthkeys list --user <user-id>         # expire any still-valid reusable key
sudo headscale preauthkeys expire --user <user-id> <key>
```

Then revoke whatever else it held: SSH keys in `authorized_keys`, Syncthing device (remove on every peer), Sunshine pairing (web UI → Clients → unpair).
