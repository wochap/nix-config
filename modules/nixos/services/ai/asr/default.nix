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
  pipeline = pkgs.writeText "asr-pipeline.py" (builtins.readFile ./pipeline.py);
  adapterModule = pkgs.writeText "asr-${adapterName}-adapter.py" (builtins.readFile adapter.module);

  # The adapter supplies the transcriber and aligner; diarization is core.
  models = adapter.models // {
    diarizer = {
      repo = "pyannote/speaker-diarization-community-1";
      revision = "3533c8cf8e369892e6b79ff1bf80f7b0286a54ee";
      role = "diarizer";
    };
  };

  # CUDA adds pyannote to the adapter's upstream image; ROCm builds the
  # adapter's packages and pyannote on the ROCm PyTorch base.
  image =
    if isRocm then
      aiLib.mkContainerImage "asr-${adapterName}-rocm" ./rocm.Containerfile ''
        BASE_IMAGE=${asrCfg.rocm.baseImage}
        EXTRA_PIP_PACKAGES=${lib.concatStringsSep " " adapter.pipPackages}''
    else
      aiLib.mkContainerImage "asr-${adapterName}-cuda" ./cuda.Containerfile
        "BASE_IMAGE=${adapter.image.cuda.tag}";

  asr = pkgs.writeShellApplication {
    name = "asr";
    runtimeInputs = [
      pkgs.python3
      pkgs.ffmpeg-headless
    ];
    runtimeEnv =
      aiLib.mkGpuEnv {
        gpu = asrCfg;
        inherit image;
        label = "${adapterName} ${toString asrCfg.accelerator}";
      }
      // {
        ASR_ADAPTER = adapterName;
        ASR_ADAPTER_MODULE = adapterModule;
        ASR_MODELS_FILE = pkgs.writeText "asr-${adapterName}-models.json" (builtins.toJSON models);
        ASR_DTYPE = asrCfg.dtype;
        ASR_BATCH_SIZE = toString asrCfg.batchSize;
        ASR_DEFAULT_CHUNK_SECONDS = toString asrCfg.chunkSeconds;
        ASR_HF_TOKEN_FILE = config.sops.secrets.personal-huggingface-local-read-token.path;
        ASR_PIPELINE_SCRIPT = pipeline;
      };
    text = builtins.readFile ../lib/container.sh + builtins.readFile ./asr.sh;
    meta.description = "Transcribe an audio or video file with speaker diarization";
  };
in
{
  imports = [
    ./adapters/qwen3
    {
      options._custom.services.ai.asr = aiLib.mkGpuOptions {
        inherit cfg;
        dtype = "bfloat16";
        shmSize = "4g";
        tmpSize = "4g";
      };
    }
  ];

  options._custom.services.ai.asr = {
    enable = lib.mkEnableOption { };

    adapter = lib.mkOption {
      type = lib.types.str;
      default = "qwen3";
      description = ''
        ASR adapter under ./adapters. It supplies the models, their
        pins, the CUDA image, and the extra ROCm pip packages.
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
                Upstream CUDA image holding the adapter's packages, extended
                with pyannote; null means CUDA is unsupported.
              '';
            };
            pipPackages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "pip requirements added to the ROCm image.";
            };
            models = lib.mkOption {
              description = ''
                Pinned Hugging Face models, keyed by the name the Python
                adapter looks them up with. The core adds `diarizer`.
              '';
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    repo = lib.mkOption {
                      type = lib.types.str;
                      description = "Hugging Face repository id.";
                    };
                    revision = lib.mkOption {
                      type = lib.types.str;
                      description = "Commit the model is pinned to.";
                    };
                    role = lib.mkOption {
                      type = lib.types.enum [
                        "transcriber"
                        "aligner"
                      ];
                      description = "Pipeline step the model serves.";
                    };
                  };
                }
              );
            };
          };
        }
      );
    };

    batchSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = ''
        Number of audio chunks asr transcribes in one generate
        call. Decoding is memory bound, so batching speeds it up nearly
        linearly until VRAM runs out. Each extra chunk of chunkSeconds
        audio costs roughly 1 GB at 480 s.
      '';
    };

    chunkSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 240;
      description = ''
        Default chunk length for asr. Longer chunks need more VRAM;
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
        assertion = adapter == null || !(adapter.models ? diarizer);
        message = ''
          The ASR adapter "${adapterName}" must not name a model `diarizer`;
          the core provides it.
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

    environment.systemPackages = [ asr ];
  };
}
