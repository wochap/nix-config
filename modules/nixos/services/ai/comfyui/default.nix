{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  ccfg = cfg.comfyui;
  isRocm = ccfg.accelerator == "rocm";
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName homeDirectory;
  source = inputs.comfyui;
  revision = source.rev or (throw "The comfyui flake input must be locked to a Git revision");
  ociBackend = config.virtualisation.oci-containers.backend;
  serviceName = "${ociBackend}-comfyui";
  proxy = config._custom.services.web-proxies.comfyui;

  # Upstream ships no Containerfile, so join the pinned source with ours.
  context = pkgs.runCommand "comfyui-context" { } ''
    mkdir -p "$out"
    cp -r ${source} "$out/ComfyUI"
    cp ${./Containerfile} "$out/Containerfile"
    cp ${./extra_model_paths.yaml} "$out/extra_model_paths.yaml"
  '';
  baseImage = if isRocm then ccfg.rocm.baseImage else ccfg.cuda.baseImage;
  extraPip = lib.concatStringsSep " " ccfg.extraPipPackages;
  # The tag carries a hash of the recipe so a changed Containerfile, base
  # image or pip package list rebuilds the image.
  recipeHash = builtins.substring 0 16 (
    builtins.hashString "sha256" (
      builtins.readFile ./Containerfile
      + builtins.readFile ./extra_model_paths.yaml
      + baseImage
      + extraPip
    )
  );
  tag = "${builtins.substring 0 7 revision}-${recipeHash}";

  dataSubdirs = [
    "models"
    "custom_nodes"
    "input"
    "output"
    "temp"
    "user"
    ".cache"
  ]
  ++ map (m: "models/${m}") ccfg.modelSubdirs
  ++ lib.optional (isRocm && ccfg.rocm.tunableOp) ".cache/tunableop";
in
{
  options._custom.services.ai.comfyui = {
    enable = lib.mkEnableOption "ComfyUI";

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
        GPU backend. It selects the base image and the devices handed to
        Podman.
      '';
    };

    cuda.baseImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/pytorch/pytorch:2.14.0-cuda13.0-cudnn9-runtime@sha256:9c99fafa01edfaa3d16da8c209b38b5970bb6fd6e72725ef60efc901489f70c6";
      description = "CUDA PyTorch image the local comfyui image is built from.";
    };

    rocm.baseImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/rocm/pytorch:rocm7.14.1_ubuntu24.04_py3.12_pytorch_release_2.12.0@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
      description = "ROCm PyTorch image the local comfyui image is built from.";
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

    rocm.tunableOp = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable PyTorch TunableOp with rocBLAS only. It benchmarks every GEMM
        shape once and keeps the fastest rocBLAS solution in
        dataDir/.cache/tunableop. Useful on cards where the default rocBLAS
        heuristic is slow and hipBLASLt ships no kernels (RDNA2). New shapes
        (resolution, prompt length) are tuned on first use, which slows that
        run.
      '';
    };

    extraPipPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "opencv-python-headless" ];
      description = ''
        Extra pip requirements baked into the image, such as custom node
        dependencies. Changing the list changes the tag and rebuilds the image.
      '';
    };

    unetDtype = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "fp32"
          "fp16"
          "bf16"
          "fp8_e4m3fn"
          "fp8_e5m2"
        ]
      );
      default = null;
      example = "bf16";
      description = ''
        Diffusion model dtype, passed as --<dtype>-unet. null lets ComfyUI
        pick from the card and the model, which means fp32 on RDNA2 for
        models that only support bf16.
      '';
    };

    attention = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "pytorch"
          "split"
          "quad"
          "sage"
          "flash"
          "ck"
        ]
      );
      default = null;
      example = "pytorch";
      description = ''
        Cross attention implementation, passed as --use-<name>-cross-attention
        (--use-<name>-attention for sage, flash and ck). null lets ComfyUI
        pick. sage and flash need their pip package in extraPipPackages.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--lowvram" ];
      description = "Extra arguments appended to main.py.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/ComfyUI";
      defaultText = lib.literalExpression ''"''${homeDirectory}/ComfyUI"'';
      description = "Host directory mounted at /data (models, inputs, outputs, custom nodes, caches).";
    };

    modelSubdirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "checkpoints"
        "diffusion_models"
        "text_encoders"
        "vae"
        "loras"
        "clip_vision"
        "controlnet"
        "upscale_models"
        "embeddings"
      ];
      description = "Directories created below dataDir/models.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID the container runs as. It must own dataDir.";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "GID the container runs as.";
    };

    shmSize = lib.mkOption {
      type = lib.types.str;
      default = "1g";
      description = "Value passed to podman run --shm-size.";
    };

    tmpSize = lib.mkOption {
      type = lib.types.str;
      default = "4g";
      description = "Size of the tmpfs mounted at /tmp inside the container.";
    };
  };

  config = lib.mkIf (cfg.enable && ccfg.enable) {
    assertions = [
      {
        assertion = ccfg.accelerator != null;
        message = ''
          _custom.services.ai.comfyui.enable needs a GPU backend: set
          enableCuda, enableRocm, or _custom.services.ai.comfyui.accelerator.
        '';
      }
    ];

    _custom.services.local-oci-images.comfyui = {
      source = context;
      inherit tag;
      dockerfile = "Containerfile";
      buildArgs = {
        BASE_IMAGE = baseImage;
        EXTRA_PIP_PACKAGES = extraPip;
      };
    };

    _custom.services.web-proxies.comfyui = {
      enable = true;
      subdomain = "comfyui";
      inherit serviceName;
      publicPort = 20500;
      backendPort = 20501;
      lazy = true;
    };

    virtualisation.oci-containers.containers.comfyui = {
      inherit serviceName;
      cmd = [
        "--listen"
        wochap-ssc.meta.address
        "--port"
        (toString proxy.backendPort)
        "--base-directory"
        "/data"
        "--extra-model-paths-config"
        "/opt/comfyui-image/extra_model_paths.yaml"
        "--disable-auto-launch"
      ]
      ++ lib.optional (ccfg.unetDtype != null) "--${ccfg.unetDtype}-unet"
      ++ lib.optional (ccfg.attention != null) (
        if
          lib.elem ccfg.attention [
            "pytorch"
            "split"
            "quad"
          ]
        then
          "--use-${ccfg.attention}-cross-attention"
        else
          "--use-${ccfg.attention}-attention"
      )
      ++ ccfg.extraArgs;
      volumes = [ "${ccfg.dataDir}:/data:rw" ];
      environment = {
        HF_HUB_DISABLE_TELEMETRY = "1";
      }
      // lib.optionalAttrs (isRocm && ccfg.rocm.gfxOverride != null) {
        HSA_OVERRIDE_GFX_VERSION = ccfg.rocm.gfxOverride;
      }
      // lib.optionalAttrs (isRocm && ccfg.rocm.tunableOp) {
        PYTORCH_TUNABLEOP_ENABLED = "1";
        PYTORCH_TUNABLEOP_HIPBLASLT_ENABLED = "0";
        PYTORCH_TUNABLEOP_ROCBLAS_ENABLED = "1";
        PYTORCH_TUNABLEOP_FILENAME = "/data/.cache/tunableop/results%d.csv";
      };
      extraOptions = [
        "--network=host"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs=/tmp:rw,nosuid,nodev,size=${ccfg.tmpSize}"
        "--pids-limit=1024"
        "--shm-size=${ccfg.shmSize}"
        "--user=${toString ccfg.uid}:${toString ccfg.gid}"
      ]
      ++ (
        if isRocm then
          map (d: "--device=${d}") ccfg.rocm.devices
          # Numeric ids: group names resolve against the image's /etc/group.
          ++ [
            "--group-add=${toString config.users.groups.video.gid}"
            "--group-add=${toString config.users.groups.render.gid}"
          ]
        else
          [ "--device=nvidia.com/gpu=all" ]
      );
    };

    # custom_nodes must exist or ComfyUI fails at startup.
    systemd.tmpfiles.rules = [
      "d ${ccfg.dataDir} 0755 ${userName} users -"
    ]
    ++ map (d: "d ${ccfg.dataDir}/${d} 0755 ${userName} users -") dataSubdirs;

    hardware.nvidia-container-toolkit.enable = lib.mkIf (!isRocm) true;

    # The container keeps its VRAM while idle; stop the unit to free it.
    # No ProtectHome: dataDir is a bind mount below /home.
    systemd.services.${serviceName} = {
      wants = lib.optional (!isRocm) "nvidia-container-toolkit-cdi-generator.service";
      after = lib.optional (!isRocm) "nvidia-container-toolkit-cdi-generator.service";
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 45;
      };
    };
  };
}
