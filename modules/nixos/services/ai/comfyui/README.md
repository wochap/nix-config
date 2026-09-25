# ComfyUI

[ComfyUI](https://github.com/comfy-org/ComfyUI) is a node-based UI for image
and video diffusion models. It lives at <https://comfyui.wochap.local> and
runs in a sandboxed Podman container that only sees `~/ComfyUI`.

## Stack

| Component                                                        | Role                                                      |
| ---------------------------------------------------------------- | --------------------------------------------------------- |
| ComfyUI v0.37.0 (image built locally from `Containerfile` here) | Web UI and inference server                               |
| PyTorch base image (ROCm on gdesktop, CUDA 13 on glegion)        | GPU runtime                                               |
| Podman                                                           | Container runtime (`podman-comfyui.service`)              |
| Data directory                                                   | Models, inputs, outputs, custom nodes, caches in `~/ComfyUI` |
| Nginx                                                            | Lazy reverse proxy on port 20500                          |

## Setup

1. The first boot builds the image with `local-oci-image-comfyui.service`.
   This takes several minutes and needs network access. The ROCm image is
   about 23 GB, the CUDA image about 6 GB. Watch it with:

   ```sh
   journalctl -fu local-oci-image-comfyui
   ```

2. Open <https://comfyui.wochap.local>. The first request starts the
   container. A cold start can take more than 60 s and return 502; reload the
   page after a moment.

3. The container keeps its VRAM while idle. Free it with:

   ```sh
   sudo systemctl stop podman-comfyui
   ```

## Models

Put weights into `~/ComfyUI/models/<subdir>`, for example
`~/ComfyUI/models/diffusion_models`. The directories in `modelSubdirs` are
created by systemd-tmpfiles. Create other subdirectories by hand or add them
to `modelSubdirs`.

## Custom nodes

Clone custom nodes into `~/ComfyUI/custom_nodes` and restart
`podman-comfyui`. ComfyUI-Manager is off. The root filesystem is read-only, so
add custom node pip dependencies to `extraPipPackages`; this rebuilds the
image.

## Upgrade

1. Bump the tag of the `comfyui` input in `flake.nix`.
2. Run `nix flake update comfyui` and rebuild. A new revision produces a new
   image tag, so the image is rebuilt on start.
3. Remove the old image:

   ```sh
   sudo podman image rm localhost/comfyui:<old-tag>
   ```

## Options

All options live under `_custom.services.ai.comfyui`.

| Option             | Default                          | Notes                                                    |
| ------------------ | -------------------------------- | -------------------------------------------------------- |
| `enable`           | `false`                          |                                                          |
| `accelerator`      | from `enableCuda` / `enableRocm` | `cuda` or `rocm`                                         |
| `cuda.baseImage`   | `pytorch/pytorch` CUDA 13 digest |                                                          |
| `rocm.baseImage`   | `rocm/pytorch` digest            | Same digest as qwen3-asr                                 |
| `rocm.gfxOverride` | `null`                           | Sets `HSA_OVERRIDE_GFX_VERSION`                          |
| `rocm.devices`     | `/dev/kfd`, `/dev/dri`           |                                                          |
| `extraPipPackages` | `[]`                             | Baked into the image; changes the tag                    |
| `extraArgs`        | `[]`                             | Appended to `main.py`, such as `--lowvram`               |
| `dataDir`          | `~/ComfyUI`                      | Mounted at `/data`                                       |
| `modelSubdirs`     | common model folders             | Created below `dataDir/models`                           |
| `uid` / `gid`      | `1000` / `100`                   | Container user; must own `dataDir`                       |
| `shmSize`          | `1g`                             |                                                          |
| `tmpSize`          | `4g`                             | tmpfs at `/tmp`                                          |

## Notes

- On ROCm, if `comfy-aimdo` (dynamic VRAM) fails to import, add
  `--disable-dynamic-vram` to `extraArgs`.
- `HOME` is `/data`, so MIOpen and Triton caches survive restarts in
  `~/ComfyUI/.cache`.
