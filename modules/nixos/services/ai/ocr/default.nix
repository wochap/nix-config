{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
  pdfIngestCfg = cfg.pdfIngest;
  isRocm = pdfIngestCfg.accelerator == "rocm";
  python = pkgs.python3;
  rapidocrPython = python.withPackages (_: [ pkgs._custom.rapidocr ]);
  pdfIngestPython = python.withPackages (pythonPackages: [ pythonPackages.pymupdf ]);
  rapidocrEntrypoint = pkgs.writeText "rapidocr-text.py" (builtins.readFile ./rapidocr-text.py);
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
  rocmImage =
    mkContainerImage "pdf-ingest-rocm" ./pdf-ingest-rocm.Containerfile
      pdfIngestCfg.rocm.baseImage;

  # CUDA runs the upstream offline image directly and builds nothing.
  image = if isRocm then rocmImage else null;

  ocr = pkgs.writeShellApplication {
    name = "ocr";
    runtimeEnv = {
      OCR_RAPID_ENTRYPOINT = rapidocrEntrypoint;
      OCR_RAPID_PYTHON = "${rapidocrPython}/bin/python";
    };
    text = builtins.readFile ./ocr.sh;
  };
  pdf-ingest = pkgs.writeShellApplication {
    name = "pdf-ingest";
    runtimeInputs = [
      pdfIngestPython
    ];
    runtimeEnv = {
      PDF_INGEST_ACCELERATOR = if isRocm then "rocm" else "cuda";
      PDF_INGEST_GPU_DEVICES =
        if isRocm then lib.concatStringsSep " " pdfIngestCfg.rocm.devices else "nvidia.com/gpu=all";
      PDF_INGEST_HSA_OVERRIDE_GFX_VERSION =
        if isRocm && pdfIngestCfg.rocm.gfxOverride != null then pdfIngestCfg.rocm.gfxOverride else "";
      PDF_INGEST_DTYPE = pdfIngestCfg.dtype;
      PDF_INGEST_SHM_SIZE = pdfIngestCfg.shmSize;
      PDF_INGEST_TMP_SIZE = pdfIngestCfg.tmpSize;
      PDF_INGEST_IMAGE = if image == null then pdfIngestCfg.cuda.image else image.tag;
      PDF_INGEST_IMAGE_CONTEXT = if image == null then "" else "${image.context}";
      PDF_INGEST_IMAGE_BUILD_ARGS = if image == null then "" else image.buildArgs;
      # The upstream image ships native Paddle inference; the ROCm image has
      # no Paddle HIP build for gfx1030 and runs the models through
      # Transformers on ROCm PyTorch instead.
      PDF_INGEST_ENGINE = if isRocm then "transformers" else "paddle";
      # Read-only model cache baked into the image. The upstream image runs as
      # the paddleocr user; the rocm/pytorch base runs as root.
      PDF_INGEST_BUNDLED_CACHE = if isRocm then "/root/.paddlex" else "/home/paddleocr/.paddlex";
      PDF_INGEST_PIPELINE = pdfIngestPipeline;
      PDF_INGEST_PYTHON = "${pdfIngestPython}/bin/python";
    };
    text = builtins.readFile ./pdf-ingest-image.sh + builtins.readFile ./pdf-ingest.sh;
    meta.description = "Extract a PDF into a portable canonical document directory";
  };
in
{
  options._custom.services.ai = {
    enableOcr = lib.mkEnableOption { };

    pdfIngest = {
      accelerator = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "cuda"
            "rocm"
          ]
        );
        default =
          if cfg.enableNvidia then
            "cuda"
          else if cfg.enableRocm then
            "rocm"
          else
            null;
        defaultText = lib.literalExpression ''"cuda" when enableNvidia, "rocm" when enableRocm'';
        description = ''
          GPU backend used by pdf-ingest. It selects the container image, the
          inference engine, and the devices handed to Podman.
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

      cuda.image = lib.mkOption {
        type = lib.types.str;
        default = "ccr-2vdh3abv-pub.cnc.bj.baidubce.com/paddlepaddle/paddleocr-vl:paddleocr3.6-nvidia-gpu-offline@sha256:6c735bdf9e758ffdd58ccc067db0c2d84e37e5e6a2cbd47156069d4d7ea5d709";
        description = "Upstream PaddleOCR-VL offline CUDA image, run directly.";
      };

      rocm.baseImage = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/rocm/pytorch@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
        description = ''
          ROCm PyTorch image the local pdf-ingest-rocm image is built from.
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

  config = lib.mkIf cfg.enableOcr {
    assertions = [
      {
        assertion = pdfIngestCfg.accelerator != null;
        message = ''
          _custom.services.ai.enableOcr needs a GPU backend for pdf-ingest: set
          enableNvidia, enableRocm, or _custom.services.ai.pdfIngest.accelerator.
        '';
      }
    ];

    environment.systemPackages = with pkgs; [
      ocr
      pdf-ingest
    ];

    services.ollama.loadModels = lib.mkAfter [ "glm-ocr:bf16" ];
  };
}
