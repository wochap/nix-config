{
  config,
  pkgs,
  lib,
  aiLib,
  ...
}:

let
  cfg = config._custom.services.ai;
  asrCfg = cfg.asr;
  isRocm = asrCfg.accelerator == "rocm";
  inherit (config._custom.globals) userName;
  adapterName = asrCfg.adapter;
  adapter = asrCfg.adapterRegistry.${adapterName} or null;
  diarizer-revision = "3533c8cf8e369892e6b79ff1bf80f7b0286a54ee";
  transcribeScript = pkgs.writeText "asr-transcribe.py" (builtins.readFile ./transcribe.py);
  pipeline = pkgs.writeText "asr-pipeline.py" (builtins.readFile ./pipeline.py);
  adapterModule = pkgs.writeText "asr-${adapterName}-adapter.py" (builtins.readFile adapter.module);

  diarizationImage =
    aiLib.mkContainerImage "asr-${adapterName}-diarization" ./diarization.Containerfile
      "BASE_IMAGE=${adapter.image.cuda.tag}";
  rocmImage = aiLib.mkContainerImage "asr-${adapterName}-rocm" ./rocm.Containerfile ''
    BASE_IMAGE=${asrCfg.rocm.baseImage}
    EXTRA_PIP_PACKAGES=${lib.concatStringsSep " " adapter.pipPackages}'';

  # asr-transcribe needs no extra packages on CUDA, so it runs the adapter's
  # upstream image directly and builds nothing.
  transcribeImage = if isRocm then rocmImage else adapter.image.cuda;
  videoImage = if isRocm then rocmImage else diarizationImage;
  imageEnv =
    image: label:
    aiLib.mkGpuEnv {
      gpu = asrCfg;
      inherit image label;
    };

  revisionEnv = lib.mapAttrs' (
    key: value: lib.nameValuePair "ASR_REVISION_${lib.toUpper key}" value
  ) adapter.revisions;

  asrEnv = revisionEnv // {
    ASR_ADAPTER = adapterName;
    ASR_ADAPTER_MODULE = adapterModule;
    ASR_REVISION_VARS = lib.concatStringsSep " " (lib.attrNames revisionEnv);
    ASR_TRANSCRIBER_FILES = lib.concatStringsSep " " adapter.cachedFiles.transcriber;
    ASR_DTYPE = asrCfg.dtype;
    ASR_BATCH_SIZE = toString asrCfg.batchSize;
    ASR_SHM_SIZE = asrCfg.shmSize;
    ASR_TMP_SIZE = asrCfg.tmpSize;
  };
  gpuOptions = aiLib.mkGpuOptions {
    inherit cfg;
    dtype = "bfloat16";
    shmSize = "4g";
    tmpSize = "4g";
  };
  launcher =
    script:
    builtins.readFile ../lib/container.sh + builtins.readFile ./image.sh + builtins.readFile script;

  asr-transcribe = pkgs.writeShellApplication {
    name = "asr-transcribe";
    runtimeEnv =
      asrEnv
      // imageEnv transcribeImage "${adapterName} ${asrCfg.accelerator}"
      // {
        ASR_SCRIPT = transcribeScript;
      };
    text = launcher ./transcribe.sh;
  };
  asr-video = pkgs.writeShellApplication {
    name = "asr-video";
    runtimeEnv =
      asrEnv
      // imageEnv videoImage "${adapterName} ${if isRocm then "rocm" else "diarization"}"
      // {
        ASR_DEFAULT_CHUNK_SECONDS = toString asrCfg.chunkSeconds;
        ASR_ALIGNER_FILES = lib.concatStringsSep " " adapter.cachedFiles.aligner;
        ASR_DIARIZER_REVISION = diarizer-revision;
        ASR_HF_TOKEN_FILE = config.sops.secrets.personal-huggingface-local-read-token.path;
        ASR_PIPELINE_SCRIPT = pipeline;
      };
    text = launcher ./video.sh;
  };
in
{
  imports = [
    ./adapters/qwen3
  ];

  # recursiveUpdate keeps rocm.baseImage beside the shared rocm options.
  options._custom.services.ai.asr = lib.recursiveUpdate gpuOptions {
    enable = lib.mkEnableOption { };

    adapter = lib.mkOption {
      type = lib.types.str;
      default = "qwen3";
      description = ''
        ASR adapter under ./adapters. It supplies the models, their
        revisions, the CUDA image, and the extra ROCm pip packages.
      '';
    };

    adapterRegistry = lib.mkOption {
      internal = true;
      default = { };
      description = "ASR adapters registered by the modules under ./adapters.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            module = lib.mkOption {
              type = lib.types.path;
              description = "Python adapter, mounted at /opt/asr/adapter.py.";
            };
            image.cuda = lib.mkOption {
              type = lib.types.nullOr aiLib.imageType;
              default = null;
              description = ''
                Upstream CUDA image holding the adapter's packages; null means
                CUDA is unsupported. ROCm builds the core image instead.
              '';
            };
            pipPackages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "pip requirements added to the ROCm image.";
            };
            revisions = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "Model pins, exported as ASR_REVISION_<KEY>.";
            };
            cachedFiles = {
              transcriber = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Files, relative to the model cache, that asr-transcribe needs offline.";
              };
              aligner = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Files, relative to the model cache, that the aligner needs offline.";
              };
            };
          };
        }
      );
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

    rocm.baseImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/rocm/pytorch@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
      description = ''
        ROCm PyTorch image the local asr-<adapter>-rocm image is built from.
      '';
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
      {
        assertion = adapter != null;
        message = ''
          _custom.services.ai.asr.adapter is "${adapterName}", which is not
          one of: ${lib.concatStringsSep ", " (lib.attrNames asrCfg.adapterRegistry)}.
        '';
      }
      {
        assertion = adapter == null || asrCfg.accelerator != "cuda" || adapter.image.cuda != null;
        message = ''
          The ASR adapter "${adapterName}" does not support the cuda accelerator.
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
