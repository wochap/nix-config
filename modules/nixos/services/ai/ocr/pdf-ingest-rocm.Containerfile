ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# PaddleX pins the non-headless OpenCV wheel, which links against libGL even
# though nothing here opens a window.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Keep the base image's ROCm PyTorch build. The constraints file pins the
# installed torch packages so pip resolves the new dependencies around them
# instead of pulling the CUDA wheels from PyPI. pip list is used rather than
# pip freeze because locally built wheels are reported as direct file
# references that cannot be used as constraints. No paddlepaddle wheel is
# installed: with the Transformers engine PaddleX runs both models on torch.
RUN python3 -m pip list --format=freeze \
      | grep -iE '^(torch|torchaudio|torchvision|pytorch-triton-rocm)==' \
      > /tmp/torch-constraints.txt \
    && test -s /tmp/torch-constraints.txt \
    && python3 -m pip install --no-cache-dir -c /tmp/torch-constraints.txt \
      "paddleocr[doc-parser]==3.7.0" "paddlex==3.7.2" "transformers==5.17.0" \
    && python3 -m pip check

# Bake the model weights and the visualisation font into the image at the
# paths PaddleX resolves for the Transformers engine. pdf-ingest runs the
# container with --network=none and a read-only rootfs, so nothing can be
# downloaded at runtime. The directory names mirror PaddleX's own Hugging
# Face hoster: the layout model gets the _safetensors suffix and the VL model
# loses its -0.9B suffix.
RUN python3 - <<'EOF'
from pathlib import Path

from huggingface_hub import snapshot_download

models = Path("/root/.paddlex/official_models")
for repo, name in (
    ("PaddlePaddle/PP-DocLayoutV3_safetensors", "PP-DocLayoutV3_safetensors"),
    ("PaddlePaddle/PaddleOCR-VL-1.6", "PaddleOCR-VL-1.6"),
):
    snapshot_download(repo_id=repo, local_dir=models / name)

from paddlex.utils.fonts import PINGFANG_FONT

font = Path(PINGFANG_FONT.path)
assert font.is_file(), font
assert font.parent == Path("/root/.paddlex/fonts"), font
EOF

# Prove the image works offline before it is ever used: mimic the launcher's
# writable cache with links back to the baked resources, then build the
# pipeline with the Transformers engine on the CPU and parse a blank page.
# The CPU keeps the build independent of GPU access; float32 is used because
# CPU kernels do not cover float16.
RUN HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 PADDLE_PDX_CACHE_HOME=/tmp/verify \
    PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True python3 - <<'EOF'
from pathlib import Path

from PIL import Image

cache = Path("/tmp/verify")
cache.mkdir(parents=True, exist_ok=True)
for name in ("official_models", "fonts"):
    (cache / name).symlink_to(Path("/root/.paddlex") / name, target_is_directory=True)

image = cache / "blank.png"
Image.new("RGB", (640, 480), "white").save(image)

from paddleocr import PaddleOCRVL

pipeline = PaddleOCRVL(
    pipeline_version="v1.6",
    device="cpu",
    engine="transformers",
    engine_config={"dtype": "float32"},
    use_doc_orientation_classify=False,
    use_doc_unwarping=False,
    use_layout_detection=True,
    use_chart_recognition=True,
    use_queues=False,
    vl_rec_backend="native",
    vl_rec_max_concurrency=1,
)
results = list(pipeline.predict(input=str(image), use_queues=False))
assert len(results) == 1, results
print("offline verification passed:", results[0].json)
EOF

LABEL org.opencontainers.image.title="pdf-ingest-rocm"
