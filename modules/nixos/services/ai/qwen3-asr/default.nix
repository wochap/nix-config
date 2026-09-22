{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  asrCfg = cfg.qwen3Asr;
  isRocm = asrCfg.accelerator == "rocm";
  inherit (config._custom.globals) userName;
  asr-revision = "7278e1e70fe206f11671096ffdd38061171dd6e5";
  aligner-revision = "c7cbfc2048c462b0d63a45797104fc9db3ad62b7";
  diarizer-revision = "3533c8cf8e369892e6b79ff1bf80f7b0286a54ee";
  transformers = pkgs.writeText "qwen3-asr-transformers.py" (
    builtins.readFile ./qwen3-asr-transformers.py
  );
  pipeline = pkgs.writeText "qwen3-asr-pipeline.py" (builtins.readFile ./qwen3-asr-pipeline.py);

  # One build context per Containerfile. The tag carries a hash of the
  # Containerfile and its base image so a changed recipe rebuilds the image.
  mkContainerImage = name: file: baseImage: rec {
    version = builtins.substring 0 16 (
      builtins.hashString "sha256" (builtins.readFile file + baseImage)
    );
    tag = "localhost/${name}:${version}";
    context = pkgs.runCommand "${name}-context" { } ''
      mkdir -p "$out"
      cp ${file} "$out/Containerfile"
    '';
    buildArgs = "BASE_IMAGE=${baseImage}";
  };
  diarizationImage =
    mkContainerImage "qwen3-asr-diarization" ./qwen3-asr-diarization.Containerfile
      asrCfg.cuda.image;
  rocmImage = mkContainerImage "qwen3-asr-rocm" ./qwen3-asr-rocm.Containerfile asrCfg.rocm.baseImage;

  # qwen3-asr-transcribe needs no extra packages on CUDA, so it runs the
  # upstream image directly and builds nothing.
  transcribeImage = if isRocm then rocmImage else null;
  videoImage = if isRocm then rocmImage else diarizationImage;

  gpuEnv = {
    QWEN3_ASR_ACCELERATOR = if isRocm then "rocm" else "cuda";
    QWEN3_ASR_GPU_DEVICES =
      if isRocm then lib.concatStringsSep " " asrCfg.rocm.devices else "nvidia.com/gpu=all";
    QWEN3_ASR_HSA_OVERRIDE_GFX_VERSION =
      if isRocm && asrCfg.rocm.gfxOverride != null then asrCfg.rocm.gfxOverride else "";
    QWEN3_ASR_DTYPE = asrCfg.dtype;
    QWEN3_ASR_BATCH_SIZE = toString asrCfg.batchSize;
    QWEN3_ASR_SHM_SIZE = asrCfg.shmSize;
    QWEN3_ASR_TMP_SIZE = asrCfg.tmpSize;
  };
  imageEnv = image: {
    QWEN3_ASR_IMAGE = if image == null then asrCfg.cuda.image else image.tag;
    QWEN3_ASR_IMAGE_CONTEXT = if image == null then "" else "${image.context}";
    QWEN3_ASR_IMAGE_BUILD_ARGS = if image == null then "" else image.buildArgs;
  };

  qwen3-asr-transcribe = pkgs.writeShellApplication {
    name = "qwen3-asr-transcribe";
    runtimeEnv =
      gpuEnv
      // imageEnv transcribeImage
      // {
        QWEN3_ASR_ASR_REVISION = asr-revision;
        QWEN3_ASR_SCRIPT = transformers;
      };
    text = builtins.readFile ./qwen3-asr-image.sh + builtins.readFile ./qwen3-asr-transcribe.sh;
  };
  qwen3-asr-video = pkgs.writeShellApplication {
    name = "qwen3-asr-video";
    runtimeEnv =
      gpuEnv
      // imageEnv videoImage
      // {
        QWEN3_ASR_DEFAULT_CHUNK_SECONDS = toString asrCfg.chunkSeconds;
        QWEN3_ASR_ASR_REVISION = asr-revision;
        QWEN3_ASR_ALIGNER_REVISION = aligner-revision;
        QWEN3_ASR_DIARIZER_REVISION = diarizer-revision;
        QWEN3_ASR_HF_TOKEN_FILE = config.sops.secrets.personal-huggingface-local-read-token.path;
        QWEN3_ASR_PIPELINE_SCRIPT = pipeline;
      };
    text = builtins.readFile ./qwen3-asr-image.sh + builtins.readFile ./qwen3-asr-video.sh;
  };
in
{
  options._custom.services.ai = {
    qwen3Asr = {
      enable = lib.mkEnableOption { };

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
          Number of audio chunks qwen3-asr-video transcribes in one generate
          call. Decoding is memory bound, so batching speeds it up nearly
          linearly until VRAM runs out. Each extra chunk of chunkSeconds
          audio costs roughly 1 GB at 480 s.
        '';
      };

      chunkSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 240;
        description = ''
          Default chunk length for qwen3-asr-video. Longer chunks need more
          VRAM; QWEN3_ASR_CHUNK_SECONDS overrides it per run.
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
        default = "docker.io/qwenllm/qwen3-asr@sha256:fb75b775f089e06e5a1aaebffd421e37505cc630d50c86d889d95ffa45a7e16a";
        description = ''
          Upstream CUDA image. qwen3-asr-transcribe runs it directly and
          qwen3-asr-video builds the diarization image on top of it.
        '';
      };

      rocm.baseImage = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/rocm/pytorch@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
        description = ''
          ROCm PyTorch image the local qwen3-asr-rocm image is built from.
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
          _custom.services.ai.qwen3Asr.enable needs a GPU backend: set
          enableCuda, enableRocm, or _custom.services.ai.qwen3Asr.accelerator.
        '';
      }
    ];

    sops.secrets.personal-huggingface-local-read-token = {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
      owner = userName;
    };

    environment.systemPackages = [
      qwen3-asr-transcribe
      qwen3-asr-video
    ];
  };
}
