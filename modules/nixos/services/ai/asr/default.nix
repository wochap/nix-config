{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  asrCfg = cfg.asr;
  isRocm = asrCfg.accelerator == "rocm";
  inherit (config._custom.globals) userName;
  adapter = import (./adapters + "/${asrCfg.backend}") { inherit pkgs lib; };
  diarizer-revision = "3533c8cf8e369892e6b79ff1bf80f7b0286a54ee";
  transcribeScript = pkgs.writeText "asr-transcribe.py" (builtins.readFile ./transcribe.py);
  pipeline = pkgs.writeText "asr-pipeline.py" (builtins.readFile ./pipeline.py);
  adapterModule = pkgs.writeText "asr-${adapter.name}-adapter.py" (builtins.readFile adapter.module);

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
  diarizationImage =
    mkContainerImage "asr-${adapter.name}-diarization" ./diarization.Containerfile
      "BASE_IMAGE=${asrCfg.cuda.image}";
  rocmImage = mkContainerImage "asr-${adapter.name}-rocm" ./rocm.Containerfile ''
    BASE_IMAGE=${asrCfg.rocm.baseImage}
    EXTRA_PIP_PACKAGES=${lib.concatStringsSep " " adapter.pipPackages}'';

  # asr-transcribe needs no extra packages on CUDA, so it runs the upstream
  # backend image directly and builds nothing.
  transcribeImage = if isRocm then rocmImage else null;
  videoImage = if isRocm then rocmImage else diarizationImage;

  revisionEnv = lib.mapAttrs' (
    key: value: lib.nameValuePair "ASR_REVISION_${lib.toUpper key}" value
  ) adapter.revisions;

  gpuEnv = revisionEnv // {
    ASR_BACKEND = adapter.name;
    ASR_ADAPTER = adapterModule;
    ASR_REVISION_VARS = lib.concatStringsSep " " (lib.attrNames revisionEnv);
    ASR_TRANSCRIBER_FILES = lib.concatStringsSep " " adapter.cachedFiles.transcriber;
    ASR_ACCELERATOR = if isRocm then "rocm" else "cuda";
    ASR_GPU_DEVICES =
      if isRocm then lib.concatStringsSep " " asrCfg.rocm.devices else "nvidia.com/gpu=all";
    ASR_HSA_OVERRIDE_GFX_VERSION =
      if isRocm && asrCfg.rocm.gfxOverride != null then asrCfg.rocm.gfxOverride else "";
    ASR_DTYPE = asrCfg.dtype;
    ASR_BATCH_SIZE = toString asrCfg.batchSize;
    ASR_SHM_SIZE = asrCfg.shmSize;
    ASR_TMP_SIZE = asrCfg.tmpSize;
  };
  imageEnv = image: {
    ASR_IMAGE = if image == null then asrCfg.cuda.image else image.tag;
    ASR_IMAGE_CONTEXT = if image == null then "" else "${image.context}";
    ASR_IMAGE_BUILD_ARGS = if image == null then "" else image.buildArgs;
  };

  asr-transcribe = pkgs.writeShellApplication {
    name = "asr-transcribe";
    runtimeEnv =
      gpuEnv
      // imageEnv transcribeImage
      // {
        ASR_SCRIPT = transcribeScript;
      };
    text = builtins.readFile ./image.sh + builtins.readFile ./transcribe.sh;
  };
  asr-video = pkgs.writeShellApplication {
    name = "asr-video";
    runtimeEnv =
      gpuEnv
      // imageEnv videoImage
      // {
        ASR_DEFAULT_CHUNK_SECONDS = toString asrCfg.chunkSeconds;
        ASR_ALIGNER_FILES = lib.concatStringsSep " " adapter.cachedFiles.aligner;
        ASR_DIARIZER_REVISION = diarizer-revision;
        ASR_HF_TOKEN_FILE = config.sops.secrets.personal-huggingface-local-read-token.path;
        ASR_PIPELINE_SCRIPT = pipeline;
      };
    text = builtins.readFile ./image.sh + builtins.readFile ./video.sh;
  };
in
{
  options._custom.services.ai = {
    asr = {
      enable = lib.mkEnableOption { };

      backend = lib.mkOption {
        type = lib.types.enum [ "qwen3" ];
        default = "qwen3";
        description = ''
          ASR backend adapter under ./adapters. It supplies the models, their
          revisions, the CUDA image, and the extra ROCm pip packages.
        '';
      };

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
          GPU backend used for inference. It selects the container image and
          the devices handed to Podman.
        '';
      };

      dtype = lib.mkOption {
        type = lib.types.enum [
          "bfloat16"
          "float16"
          "float32"
        ];
        default = "bfloat16";
        description = "Torch dtype the models are loaded with.";
      };

      batchSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
        description = ''
          Number of audio chunks asr-video transcribes in one generate
          call. Decoding is memory bound, so batching speeds it up nearly
          linearly until VRAM runs out. Each extra chunk of chunkSeconds
          audio costs roughly 1 GB at 480 s.
        '';
      };

      chunkSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 240;
        description = ''
          Default chunk length for asr-video. Longer chunks need more VRAM;
          ASR_CHUNK_SECONDS overrides it per run.
        '';
      };

      shmSize = lib.mkOption {
        type = lib.types.str;
        default = "4g";
        description = "Value passed to podman run --shm-size.";
      };

      tmpSize = lib.mkOption {
        type = lib.types.str;
        default = "4g";
        description = "Size of the tmpfs mounted at /tmp inside the container.";
      };

      cuda.image = lib.mkOption {
        type = lib.types.str;
        default = adapter.cudaImage;
        defaultText = lib.literalMD "the backend adapter's `cudaImage`";
        description = ''
          Upstream CUDA image. asr-transcribe runs it directly and asr-video
          builds the diarization image on top of it.
        '';
      };

      rocm.baseImage = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/rocm/pytorch@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
        description = ''
          ROCm PyTorch image the local asr-<backend>-rocm image is built from.
        '';
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
  };

  config = lib.mkIf (cfg.enable && asrCfg.enable) {
    assertions = [
      {
        assertion = asrCfg.accelerator != null;
        message = ''
          _custom.services.ai.asr.enable needs a GPU backend: set
          enableCuda, enableRocm, or _custom.services.ai.asr.accelerator.
        '';
      }
    ];

    sops.secrets.personal-huggingface-local-read-token = {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
      owner = userName;
    };

    environment.systemPackages = [
      asr-transcribe
      asr-video
    ];
  };
}
