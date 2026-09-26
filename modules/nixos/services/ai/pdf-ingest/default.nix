{
  config,
  lib,
  pkgs,
  aiLib,
  ...
}:

let
  cfg = config._custom.services.ai;
  pdfIngestCfg = cfg.pdfIngest;
  python = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pymupdf ]);
  pipeline = pkgs.writeText "pdf-ingest.py" (builtins.readFile ./pdf-ingest.py);

  adapter = pdfIngestCfg.adapterRegistry.${pdfIngestCfg.adapter} or null;
  accelerator = if pdfIngestCfg.accelerator == "rocm" then "rocm" else "cuda";
  image = if adapter == null then null else adapter.image.${accelerator} or null;

  pdf-ingest = pkgs.writeShellApplication {
    name = "pdf-ingest";
    runtimeInputs = [ python ];
    runtimeEnv =
      aiLib.mkGpuEnv {
        gpu = pdfIngestCfg;
        inherit image;
        label = "${adapter.displayName} ${accelerator}";
      }
      // {
        PDF_INGEST_DTYPE = pdfIngestCfg.dtype;
        PDF_INGEST_ADAPTER = pdfIngestCfg.adapter;
        PDF_INGEST_ADAPTER_MODULE = pkgs.writeText "pdf-ingest-${pdfIngestCfg.adapter}-adapter.py" (
          builtins.readFile adapter.module
        );
        # One KEY=VALUE per line, passed to the inference container.
        PDF_INGEST_CONTAINER_ENV = lib.concatStringsSep "\n" (adapter.containerEnv.${accelerator} or [ ]);
        PDF_INGEST_PIPELINE = pipeline;
        PDF_INGEST_PYTHON = "${python}/bin/python";
      };
    text = builtins.readFile ../lib/container.sh + builtins.readFile ./pdf-ingest.sh;
    meta.description = "Extract a PDF into a portable canonical document directory";
  };
in
{
  imports = [
    ./adapters/paddleocr-vl
    {
      options._custom.services.ai.pdfIngest = aiLib.mkGpuOptions {
        inherit cfg;
        dtype = "float16";
        shmSize = "2g";
        tmpSize = "4g";
        dtypeDescription = ''
          Torch dtype the models are loaded with on ROCm. An adapter that runs
          native inference on CUDA may keep its own precision there.
        '';
      };
    }
  ];

  options._custom.services.ai.pdfIngest = {
    enable = lib.mkEnableOption { };

    adapter = lib.mkOption {
      type = lib.types.str;
      default = "paddleocr-vl";
      description = ''
        Layout adapter under ./adapters. It supplies the inference image, its
        container environment, and the Python parser module.
      '';
    };

    adapterRegistry = lib.mkOption {
      internal = true;
      default = { };
      description = "Layout adapters registered by the modules under ./adapters.";
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
              type = lib.types.attrsOf (lib.types.nullOr aiLib.imageType);
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
  };

  config = lib.mkIf (cfg.enable && pdfIngestCfg.enable) {
    assertions = [
      {
        assertion = pdfIngestCfg.accelerator != null;
        message = ''
          _custom.services.ai.pdfIngest.enable needs a GPU backend: set
          enableCuda, enableRocm, or _custom.services.ai.pdfIngest.accelerator.
        '';
      }
      {
        assertion = adapter != null;
        message = ''
          _custom.services.ai.pdfIngest.adapter is "${pdfIngestCfg.adapter}",
          which is not one of:
          ${lib.concatStringsSep ", " (lib.attrNames pdfIngestCfg.adapterRegistry)}.
        '';
      }
      {
        assertion = adapter == null || pdfIngestCfg.accelerator == null || image != null;
        message = ''
          The pdf-ingest adapter "${pdfIngestCfg.adapter}" does not support
          the ${toString pdfIngestCfg.accelerator} accelerator.
        '';
      }
    ];

    environment.systemPackages = [ pdf-ingest ];
  };
}
