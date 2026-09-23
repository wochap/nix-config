# Open Design

[Open Design](https://github.com/nexu-io/open-design) is a self-hosted AI
design workspace. It lives at <https://open-design.wochap.local> and uses
OmniRoute for its text model.

## Stack

| Component                                                                    | Role                                                |
| ---------------------------------------------------------------------------- | --------------------------------------------------- |
| Open Design v0.24.0 (image built locally from upstream `deploy/Dockerfile`)  | Design daemon and web UI                            |
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

4. Image generation is optional. Leave **Media providers** unset. Add keys
   later through **Settings → Media providers** or through
   `_custom.services.ai.openDesign.environmentFile`.

## Upgrade

1. Bump the tag of the `open-design` input in `flake.nix`.
2. Run `nix flake lock --update-input open-design` and rebuild. A new
   revision produces a new image tag, so the image is rebuilt on start.
3. Remove the old image:

   ```sh
   podman image rm localhost/open-design:<old-rev>
   ```

## Notes

- Agent CLIs (claude, codex, opencode) are not bundled in the image.
- Video and HyperFrames export are not available, because the image has no
  Chromium.
