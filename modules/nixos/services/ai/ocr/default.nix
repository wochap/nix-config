{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
  ocrCfg = cfg.ocr;
  pdfIngestCfg = ocrCfg.pdfIngest;
  isRocm = pdfIngestCfg.accelerator == "rocm";
  python = pkgs.python3;
  pdfIngestPython = python.withPackages (pythonPackages: [ pythonPackages.pymupdf ]);
  pdfIngestPipeline = pkgs.writeText "pdf-ingest.py" (builtins.readFile ./pdf-ingest.py);

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

  screenAdapters = ocrCfg.screenAdapters;
  # Bash declarations the ocr script reads its adapters from.
  declareAdapters =
    variable: attribute:
    "declare -A ${variable}=(${
      lib.concatMapStrings (
        name: " [${name}]=${lib.escapeShellArg screenAdapters.${name}.${attribute}}"
      ) (lib.attrNames screenAdapters)
    } )\n";
  ocrPrelude = ''
    ${declareAdapters "OCR_ADAPTER_COMMANDS" "command"}
    ${declareAdapters "OCR_ADAPTER_LABELS" "label"}
    OCR_DEFAULT_ADAPTER=${lib.escapeShellArg ocrCfg.defaultScreenAdapter}
  '';

  pdfAdapter = pdfIngestCfg.adapters.${pdfIngestCfg.adapter} or null;
  accelerator = if isRocm then "rocm" else "cuda";
  image = if pdfAdapter == null then null else pdfAdapter.image.${accelerator} or null;

  ocr = pkgs.writeShellApplication {
    name = "ocr";
    text = ocrPrelude + builtins.readFile ./ocr.sh;
  };
  pdf-ingest = pkgs.writeShellApplication {
    name = "pdf-ingest";
    runtimeInputs = [
      pdfIngestPython
    ];
    runtimeEnv = {
      PDF_INGEST_ACCELERATOR = accelerator;
      PDF_INGEST_GPU_DEVICES =
        if isRocm then lib.concatStringsSep " " pdfIngestCfg.rocm.devices else "nvidia.com/gpu=all";
      PDF_INGEST_HSA_OVERRIDE_GFX_VERSION =
        if isRocm && pdfIngestCfg.rocm.gfxOverride != null then pdfIngestCfg.rocm.gfxOverride else "";
      PDF_INGEST_DTYPE = pdfIngestCfg.dtype;
      PDF_INGEST_SHM_SIZE = pdfIngestCfg.shmSize;
      PDF_INGEST_TMP_SIZE = pdfIngestCfg.tmpSize;
      PDF_INGEST_IMAGE = image.tag;
      PDF_INGEST_IMAGE_CONTEXT = image.context;
      PDF_INGEST_IMAGE_BUILD_ARGS = image.buildArgs;
      PDF_INGEST_ADAPTER = pdfIngestCfg.adapter;
      PDF_INGEST_ADAPTER_DISPLAY = pdfAdapter.displayName;
      PDF_INGEST_ADAPTER_MODULE = pkgs.writeText "pdf-ingest-${pdfIngestCfg.adapter}-adapter.py" (
        builtins.readFile pdfAdapter.module
      );
      # One KEY=VALUE per line, passed to the inference container.
      PDF_INGEST_CONTAINER_ENV = lib.concatStringsSep "\n" (
        pdfAdapter.containerEnv.${accelerator} or [ ]
      );
      PDF_INGEST_PIPELINE = pdfIngestPipeline;
      PDF_INGEST_PYTHON = "${pdfIngestPython}/bin/python";
    };
    text = builtins.readFile ./pdf-ingest-image.sh + builtins.readFile ./pdf-ingest.sh;
    meta.description = "Extract a PDF into a portable canonical document directory";
  };

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
        description = "One KEY=VALUE podman build argument.";
      };
    };
  };
in
{
  imports = [
    ./adapters/screen/rapid
    ./adapters/screen/glm
    ./adapters/pdf/paddleocr-vl
  ];

  options._custom.services.ai.ocr = {
    enable = lib.mkEnableOption { };

    screenAdapters = lib.mkOption {
      internal = true;
      default = { };
      description = ''
        Screen OCR adapters registered by the modules under
        ./adapters/screen. `ocr NAME` runs the adapter NAME.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            label = lib.mkOption {
              type = lib.types.str;
              description = "Name shown in notifications.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              description = ''
                Executable called as `command IMAGE`. It prints the text on
                stdout, exits nonzero on failure, and explains the failure on
                the last stderr line.
              '';
            };
            ollamaModels = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Models added to services.ollama.loadModels.";
            };
          };
        }
      );
    };

    defaultScreenAdapter = lib.mkOption {
      type = lib.types.str;
      default = "rapid";
      description = "Screen adapter `ocr` runs without an argument.";
    };

    pdfIngest = {
      enable = lib.mkEnableOption { };

      adapter = lib.mkOption {
        type = lib.types.str;
        default = "paddleocr-vl";
        description = ''
          Layout adapter under ./adapters/pdf. It supplies the inference
          image, its container environment, and the Python parser module.
        '';
      };

      adapters = lib.mkOption {
        internal = true;
        default = { };
        description = "PDF layout adapters registered by the modules under ./adapters/pdf.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              displayName = lib.mkOption {
                type = lib.types.str;
                description = "Name shown in log and build messages.";
              };
              module = lib.mkOption {
                type = lib.types.path;
                description = "Python adapter, mounted at /opt/pdf-ingest/adapter.py.";
              };
              image = lib.mkOption {
                type = lib.types.attrsOf (lib.types.nullOr imageType);
                default = { };
                description = "Inference image per accelerator; a missing or null entry is unsupported.";
              };
              containerEnv = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = { };
                description = "KEY=VALUE environment passed to the container, per accelerator.";
              };
            };
          }
        );
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
          GPU backend used by pdf-ingest. It selects the adapter's container
          image, its environment, and the devices handed to Podman.
        '';
      };

      dtype = lib.mkOption {
        type = lib.types.enum [
          "bfloat16"
          "float16"
          "float32"
        ];
        default = "float16";
        description = ''
          Torch dtype the models are loaded with on ROCm. The CUDA image keeps
          its native fp16 Paddle inference regardless of this value.
        '';
      };

      shmSize = lib.mkOption {
        type = lib.types.str;
        default = "2g";
        description = "Value passed to podman run --shm-size.";
      };

      tmpSize = lib.mkOption {
        type = lib.types.str;
        default = "4g";
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
  };

  config = lib.mkMerge [
    {
      _module.args.ocrLib = { inherit mkContainerImage; };
    }

    (lib.mkIf (cfg.enable && ocrCfg.enable) {
      assertions = [
        {
          assertion = screenAdapters ? ${ocrCfg.defaultScreenAdapter};
          message = ''
            _custom.services.ai.ocr.defaultScreenAdapter is
            "${ocrCfg.defaultScreenAdapter}", which is not one of:
            ${lib.concatStringsSep ", " (lib.attrNames screenAdapters)}.
          '';
        }
      ];

      environment.systemPackages = [ ocr ];

      services.ollama.loadModels = lib.mkAfter (
        lib.concatMap (adapter: adapter.ollamaModels) (lib.attrValues screenAdapters)
      );
    })

    (lib.mkIf (cfg.enable && ocrCfg.enable && pdfIngestCfg.enable) {
      assertions = [
        {
          assertion = pdfIngestCfg.accelerator != null;
          message = ''
            _custom.services.ai.ocr.pdfIngest.enable needs a GPU backend: set
            enableCuda, enableRocm, or _custom.services.ai.ocr.pdfIngest.accelerator.
          '';
        }
        {
          assertion = pdfAdapter != null;
          message = ''
            _custom.services.ai.ocr.pdfIngest.adapter is "${pdfIngestCfg.adapter}",
            which is not one of:
            ${lib.concatStringsSep ", " (lib.attrNames pdfIngestCfg.adapters)}.
          '';
        }
        {
          assertion = pdfAdapter == null || pdfIngestCfg.accelerator == null || image != null;
          message = ''
            The pdf-ingest adapter "${pdfIngestCfg.adapter}" does not support
            the ${toString pdfIngestCfg.accelerator} accelerator.
          '';
        }
      ];

      environment.systemPackages = [ pdf-ingest ];
    })
  ];
}
