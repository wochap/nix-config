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

The host sets three performance overrides. Newer AMD cards (RDNA3+) and NVIDIA
cards likely need none of them.

- `unetDtype = "fp16"`: ComfyUI treats RDNA2 as having no bf16
  (`AMD_RDNA2_AND_OLDER_ARCH`), so it runs bf16-only models such as
  Qwen-Image-2.1 in fp32. `bf16` does not help: gfx1030 has no fast bf16 path
  (matmul: fp32 8.6, bf16 9.5, fp16 36.1 TFLOPS). `fp16` gave correct images
  for Qwen-Image-2.1. If a model returns black images, set `unetDtype = null`.
- `attention = "split"`: PyTorch has no fused attention kernels for gfx1030
  (`No available kernel` for flash and memory-efficient SDPA). Per layer,
  `split` takes 25 ms, `pytorch` 172 ms and `quad` 139 ms.
- `rocm.tunableOp = true`: rocBLAS picks slow kernels for the large MLP
  matmuls (about 4.7 TFLOPS). PyTorch TunableOp times every rocBLAS kernel
  for each exact matrix shape once, keeps the fastest (about 27 TFLOPS), and
  stores it in `~/ComfyUI/.cache/tunableop`.

Shapes depend on the token count: output resolution, prompt length and
reference images. A new seed, cfg, step count or a prompt with the same token
count reuses the tuning. A new prompt length, resolution or edit input tunes
about 15 new shapes, which adds roughly 6 minutes to that run.

Long compute kernels during tuning can starve the desktop's gfx ring. With the
default 10 s `amdgpu.lockup_timeout` this forced a full GPU reset that killed
Hyprland, so `hardware.nix` raises it to 30 s.

Use GGUF or plain bf16 files. Do not use `int8`, `w4a8` or `fp8` files.
ComfyUI reports int8 compute as available on ROCm, but `torch._int_mm` runs
through hipBLASLt, which ships no gfx1030 kernels. Sampling then fails with
`HIPBLAS_STATUS_INVALID_VALUE when calling hipblasLtMatmulAlgoGetHeuristic`.

GGUF dequantizes with plain torch ops, so it works on any GPU. It needs the
[molbal/ComfyUI-GGUF](https://github.com/molbal/ComfyUI-GGUF) custom node (the
upstream city96 node fails on ComfyUI 0.27+ with "Unknown model
architecture!") and the `gguf` pip package, which gdesktop sets through
`extraPipPackages`.

#### Qwen-Image-2.1

[Qwen-Image-2.1](https://github.com/QwenLM/Qwen-Image-2.1) uses the Qwen
Research License, which does not allow commercial use. The model only runs in
bf16 or fp32.

1. Install the custom node:

   ```sh
   git clone https://github.com/molbal/ComfyUI-GGUF ~/ComfyUI/custom_nodes/ComfyUI-GGUF
   sudo systemctl restart podman-comfyui
   ```

2. Download the weights (about 25.8 GB):

   ```sh
   cd ~/ComfyUI/models
   hf download AlperKTS/Qwen-Image-2.1-GGUF qwen_image_2.1_Q8_0.gguf \
     --local-dir diffusion_models
   hf download Comfy-Org/Qwen-Image-2.1 \
     text_encoders/qwen3vl_8b_bf16.safetensors \
     vae/qwen_image_2.1_vae_bf16.safetensors \
     --local-dir .
   ```

   | File                                  | Size    | Folder              |
   | ------------------------------------- | ------- | ------------------- |
   | `qwen_image_2.1_Q8_0.gguf`            | 7.6 GB  | `diffusion_models/` |
   | `qwen3vl_8b_bf16.safetensors`         | 17.5 GB | `text_encoders/`    |
   | `qwen_image_2.1_vae_bf16.safetensors` | 0.67 GB | `vae/`              |

3. Load the text-to-image workflow from
   [AlperKTS/Qwen-Image-2.1-GGUF](https://huggingface.co/AlperKTS/Qwen-Image-2.1-GGUF/tree/main/workflows)
   by dragging it into the UI. The built-in **Qwen Image 2.1** templates use
   int8 files, so do not use them here.
4. In the workflow, set `clip_name` to `qwen3vl_8b_bf16.safetensors` (it
   defaults to an fp8 file) and keep the size at 1024×1024. Defaults: 25 steps,
   cfg 1, euler, simple.

Timings for a 1024×1024 image at 25 steps (Q8_0 fully in VRAM, GPU at 99%):

| Setup                                        | Time    |
| -------------------------------------------- | ------- |
| ComfyUI defaults (fp32, sub-quadratic)       | 17:51   |
| `fp16`, `pytorch` attention                  | 11:43   |
| `fp16`, `split`, TunableOp, tuned shapes     | 1:18    |
| Same, first run of a new prompt length       | 7:38    |

If VRAM runs out, add `--lowvram` to `extraArgs`.

## Options

All options live under `_custom.services.ai.comfyui`.

| Option             | Default                          | Notes                                                    |
| ------------------ | -------------------------------- | -------------------------------------------------------- |
| `enable`           | `false`                          |                                                          |
| `accelerator`      | from `enableCuda` / `enableRocm` | `cuda` or `rocm`                                         |
| `cuda.baseImage`   | `pytorch/pytorch` CUDA 13 digest |                                                          |
| `rocm.baseImage`   | `rocm/pytorch` digest            | Same digest as asr                                       |
| `rocm.gfxOverride` | `null`                           | Sets `HSA_OVERRIDE_GFX_VERSION`                          |
| `rocm.devices`     | `/dev/kfd`, `/dev/dri`           |                                                          |
| `rocm.tunableOp`   | `false`                          | PyTorch TunableOp with rocBLAS; cache in `dataDir/.cache/tunableop` |
| `extraPipPackages` | `[]`                             | Baked into the image; changes the tag                    |
| `unetDtype`        | `null`                           | `fp32`, `fp16`, `bf16`, `fp8_e4m3fn`, `fp8_e5m2`; `--<dtype>-unet` |
| `attention`        | `null`                           | `pytorch`, `split`, `quad`, `sage`, `flash`, `ck`        |
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
