# PaddleOCR-VL-1.6 with PP-DocLayoutV3. CUDA runs the upstream offline image
# with native Paddle inference; ROCm builds a local image that loads the same
# checkpoints through Transformers on ROCm PyTorch.
{
  config,
  lib,
  aiLib,
  ...
}:

let
  cfg = config._custom.services.ai.pdfIngest.paddleocrVl;
  rocmImage =
    aiLib.mkContainerImage "pdf-ingest-paddleocr-vl-rocm" ./rocm.Containerfile
      "BASE_IMAGE=${cfg.rocm.baseImage}";
  # PaddleX keeps its runtime cache under /tmp and links the read-only models
  # and fonts back from the image.
  commonEnv = [
    "PADDLE_PDX_CACHE_HOME=/tmp/paddlex-cache"
    "PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True"
    "FLAGS_use_mkldnn=0"
  ];
in
{
  options._custom.services.ai.pdfIngest.paddleocrVl = {
    cuda.image = lib.mkOption {
      type = lib.types.str;
      default = "ccr-2vdh3abv-pub.cnc.bj.baidubce.com/paddlepaddle/paddleocr-vl:paddleocr3.6-nvidia-gpu-offline@sha256:6c735bdf9e758ffdd58ccc067db0c2d84e37e5e6a2cbd47156069d4d7ea5d709";
      description = "Upstream PaddleOCR-VL offline CUDA image, run directly.";
    };

    rocm.baseImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/rocm/pytorch@sha256:cc9b00f90b85c97b015b040fa55c8d1b404b7cacc6ad57d74ee3451c97508da1";
      description = ''
        ROCm PyTorch image the local pdf-ingest-paddleocr-vl-rocm image is built from.
      '';
    };
  };

  config._custom.services.ai.pdfIngest.adapterRegistry.paddleocr-vl = {
    displayName = "PaddleOCR-VL";
    module = ./adapter.py;

    # CUDA runs the upstream offline image directly and builds nothing.
    image.cuda.tag = cfg.cuda.image;
    image.rocm = {
      inherit (rocmImage) tag buildArgs;
      context = "${rocmImage.context}";
    };

    # The upstream image ships native Paddle inference; the ROCm image has no
    # Paddle HIP build for gfx1030 and runs the models through Transformers on
    # ROCm PyTorch instead. The bundled cache is the read-only model cache
    # baked into the image: the upstream image runs as the paddleocr user, the
    # rocm/pytorch base runs as root.
    containerEnv.cuda = commonEnv ++ [
      "PADDLEOCR_VL_ENGINE=paddle"
      "PADDLEOCR_VL_BUNDLED_CACHE=/home/paddleocr/.paddlex"
    ];
    containerEnv.rocm = commonEnv ++ [
      "PADDLEOCR_VL_ENGINE=transformers"
      "PADDLEOCR_VL_BUNDLED_CACHE=/root/.paddlex"
    ];
  };
}
