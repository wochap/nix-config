# Open Design

[Open Design](https://github.com/nexu-io/open-design) is a self-hosted AI
design workspace. It lives at <https://open-design.wochap.local> and uses
OmniRoute for its text model.

## Stack

| Component                                                                    | Role                                                |
| ---------------------------------------------------------------------------- | --------------------------------------------------- |
| Open Design v0.24.0 fork (image built locally from `deploy/Dockerfile`)      | Design daemon and web UI                            |
| Podman                                                                       | Container runtime (`podman-open-design.service`)    |
| Data directory                                                               | Projects and state in `/var/lib/open-design`        |
| Nginx                                                                        | Reverse proxy on port 20400                         |
| OmniRoute                                                                    | Text model through the combo `open-design`          |

## Setup

1. In the OmniRoute dashboard, go to **Combos** and create a persisted combo
   named `open-design` (DeepSeek flash for now). Make sure the endpoint API
   key has access to that combo.
2. The first boot builds the image with `local-oci-image-open-design.service`.
   This takes several minutes and needs network access. Watch it with:

   ```sh
   journalctl -fu local-oci-image-open-design
   ```

3. Open <https://open-design.wochap.local> and go to **Settings → Models &
   providers**. Set:
   - Mode: API
   - Protocol: OpenAI-compatible
   - Base URL: `http://127.0.1.1:20128/v1`
   - API key: output of `cat /run/secrets/local-omniroute-secret-key`
   - Model: `open-design`

   These settings are stored in browser localStorage, so repeat this step per
   browser profile.

   The flake input tracks the fork
   [wochap/open-design](https://github.com/wochap/open-design), branch
   `open-design-v0.24.0-fork`. Upstream **Test** rejects OmniRoute combos with
   `Model '<id>' not found on this endpoint.`, because OmniRoute echoes the
   upstream model id instead of the requested alias. The fork accepts that
   echo, shows it as detail, and raises the test timeout to 30 s.

4. Image generation is optional. Leave **Media providers** unset. Add keys
   later through **Settings → Media providers** or through
   `_custom.services.ai.openDesign.environmentFile`.

## Upgrade

1. Rebase the fork branch onto the new upstream tag and push it (or point the
   `open-design` input in `flake.nix` at a new fork branch).
2. Run `nix flake lock --update-input open-design` and rebuild. A new
   revision produces a new image tag, so the image is rebuilt on start.
3. Remove the old image:

   ```sh
   podman image rm localhost/open-design:<old-rev>
   ```

## Notes

- BYOK API runs execute through the OpenCode CLI. The fork's `deploy/Dockerfile`
  bundles a pinned `opencode-ai` (`OPENCODE_VERSION`). Its state lives in the
  tmpfs `$HOME`, so it never reads host OpenCode config and resets on restart.
  Other agent CLIs (claude, codex) are not bundled.
- Video and HyperFrames export are not available, because the image has no
  Chromium.
