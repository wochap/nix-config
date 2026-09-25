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

## Hosts

### gdesktop

AMD RX 6800 XT (gfx1030, 16 GB VRAM), 32 GB RAM, ROCm. No
`rocm.gfxOverride` needed and `comfy-aimdo` (dynamic VRAM) works.

ComfyUI enables int8 compute on this card but not fp8. Use the `int8` or
`w4a8` model files and skip `fp8`. Skip GGUF too: native int8 is faster and
needs no custom node.

#### Qwen-Image-2.1

[Qwen-Image-2.1](https://huggingface.co/Comfy-Org/Qwen-Image-2.1) is supported
natively and needs no custom nodes. It uses the Qwen Research License, which
does not allow commercial use.

1. Download the weights (about 17.3 GB) into the model folders:

   ```sh
   cd ~/ComfyUI/models
   hf download Comfy-Org/Qwen-Image-2.1 \
     diffusion_models/qwen_image_2.1_int8_convrot.safetensors \
     text_encoders/qwen3vl_8b_int8_convrot.safetensors \
     vae/qwen_image_2.1_vae_bf16.safetensors \
     --local-dir .
   ```

2. Open **Templates** and pick **Qwen Image 2.1** (text to image, image edit,
   or background removal). The templates already point at these files.
3. Set the latent size to 1024×1024 for testing. The upstream default is
   2048×2048 at 40 steps, which is slow on RDNA2.

The first run fills the MIOpen and Triton caches in `~/ComfyUI/.cache`, so it
is slower than the runs after it.

If VRAM runs out, try these in order:

- Use `text_encoders/qwen3vl_8b_w4a8.safetensors` (6.3 GB) as the text
  encoder.
- Add `--lowvram` to `extraArgs`.

Do not use `qwen_image_2.1_bf16.safetensors` (14.2 GB). It is too big for
16 GB.

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
