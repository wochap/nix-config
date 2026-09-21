ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Keep the base image's ROCm PyTorch build. The constraints file pins the
# installed torch packages so pip resolves the new dependencies around them
# instead of pulling the CUDA wheels from PyPI. pip list is used rather than
# pip freeze because locally built wheels are reported as direct file
# references that cannot be used as constraints. vLLM and flash-attn are left
# out: the first is CUDA only, the second has no gfx1030 kernels.
RUN python3 -m pip list --format=freeze \
      | grep -iE '^(torch|torchaudio|torchvision|pytorch-triton-rocm)==' \
      > /tmp/torch-constraints.txt \
    && test -s /tmp/torch-constraints.txt \
    && python3 -m pip install --no-cache-dir -c /tmp/torch-constraints.txt \
      "qwen-asr==0.0.6" "pyannote.audio==4.0.4" "protobuf<7" \
    && python3 -m pip check

LABEL org.opencontainers.image.title="qwen3-asr-rocm"
