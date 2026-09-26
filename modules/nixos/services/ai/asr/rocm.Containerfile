ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Space-separated pip requirements of the adapter and the ASR core.
ARG PIP_PACKAGES

# Keep the base image's ROCm PyTorch build. The constraints file pins the
# installed torch packages so pip resolves the new dependencies around them
# instead of pulling the CUDA wheels from PyPI. pip list is used rather than
# pip freeze because locally built wheels are reported as direct file
# references that cannot be used as constraints.
RUN test -n "${PIP_PACKAGES}" \
    && python3 -m pip list --format=freeze \
      | grep -iE '^(torch|torchaudio|torchvision|pytorch-triton-rocm)==' \
      > /tmp/torch-constraints.txt \
    && test -s /tmp/torch-constraints.txt \
    && python3 -m pip install --no-cache-dir -c /tmp/torch-constraints.txt \
      ${PIP_PACKAGES} \
    && python3 -m pip check

LABEL org.opencontainers.image.title="asr-rocm"
