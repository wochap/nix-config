FROM docker.io/qwenllm/qwen3-asr@sha256:fb75b775f089e06e5a1aaebffd421e37505cc630d50c86d889d95ffa45a7e16a

# Keep the Qwen image's CUDA-enabled PyTorch installation. pip only adds the
# missing Community-1 runtime and leaves an already compatible torch in place.
RUN python3 -m pip install --no-cache-dir "pyannote.audio==4.0.4"

LABEL org.opencontainers.image.title="qwen3-asr-diarization"
