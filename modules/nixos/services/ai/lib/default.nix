# Helpers shared by the GPU container tools (asr, pdf-ingest). The AI module
# passes the result to every module as the `aiLib` argument.
{ pkgs, lib }:

{
  # One build context per Containerfile. The tag carries a hash of the
  # Containerfile and its build arguments so a changed recipe rebuilds the
  # image. buildArgs holds one argument per line.
  mkContainerImage = name: file: buildArgs: rec {
    version = builtins.substring 0 16 (
      builtins.hashString "sha256" (builtins.readFile file + buildArgs)
    );
    tag = "localhost/${name}:${version}";
    context = pkgs.runCommand "${name}-context" { } ''
      mkdir -p "$out"
      cp ${file} "$out/Containerfile"
    '';
    inherit buildArgs;
  };

  # Container image of an adapter or a tool, as consumed by mkGpuEnv.
  imageType = lib.types.submodule {
    options = {
      tag = lib.mkOption {
        type = lib.types.str;
        description = "Image reference passed to podman run.";
      };
      context = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Build context holding a Containerfile; empty runs the tag as pulled.";
      };
      buildArgs = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "podman build arguments, one KEY=VALUE per line.";
      };
    };
  };

  # GPU options of a containerized tool. `cfg` is _custom.services.ai; the
  # accelerator follows its enableCuda and enableRocm flags.
  mkGpuOptions =
    {
      cfg,
      dtype,
      shmSize,
      tmpSize,
      dtypeDescription ? "Torch dtype the models are loaded with.",
    }:
    {
      accelerator = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "cuda"
            "rocm"
          ]
        );
        default =
          if cfg.enableCuda then
            "cuda"
          else if cfg.enableRocm then
            "rocm"
          else
            null;
        defaultText = lib.literalExpression ''"cuda" when enableCuda, "rocm" when enableRocm'';
        description = ''
          GPU backend used for inference. It selects the adapter's container
          image, its environment, and the devices handed to Podman.
        '';
      };

      dtype = lib.mkOption {
        type = lib.types.enum [
          "bfloat16"
          "float16"
          "float32"
        ];
        default = dtype;
        description = dtypeDescription;
      };

      shmSize = lib.mkOption {
        type = lib.types.str;
        default = shmSize;
        description = "Value passed to podman run --shm-size.";
      };

      tmpSize = lib.mkOption {
        type = lib.types.str;
        default = tmpSize;
        description = "Size of the tmpfs mounted at /tmp inside the container.";
      };

      rocm.gfxOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10.3.0";
        description = ''
          HSA_OVERRIDE_GFX_VERSION for cards whose kernels are not shipped by
          the base image. gfx1030 (RX 6800 XT) needs none.
        '';
      };

      rocm.devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "/dev/kfd"
          "/dev/dri"
        ];
        description = "Device nodes passed to the container on ROCm.";
      };
    };

  # Environment read by container.sh. `gpu` is a tool's mkGpuOptions set,
  # `image` an imageType value, and `label` names the image in messages.
  mkGpuEnv =
    {
      gpu,
      image,
      label,
    }:
    let
      isRocm = gpu.accelerator == "rocm";
    in
    {
      AI_ACCELERATOR = if isRocm then "rocm" else "cuda";
      AI_GPU_DEVICES = if isRocm then lib.concatStringsSep " " gpu.rocm.devices else "nvidia.com/gpu=all";
      AI_HSA_OVERRIDE_GFX_VERSION =
        if isRocm && gpu.rocm.gfxOverride != null then gpu.rocm.gfxOverride else "";
      AI_IMAGE = image.tag;
      AI_IMAGE_CONTEXT = "${image.context or ""}";
      AI_IMAGE_BUILD_ARGS = image.buildArgs or "";
      AI_IMAGE_LABEL = label;
    };
}
