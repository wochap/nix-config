ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Space-separated pip requirements of the ASR core (the diarization runtime).
ARG PIP_PACKAGES

# Keep the adapter image's CUDA-enabled PyTorch installation. pip only adds
# the missing packages and leaves an already compatible torch in place. Some
# adapter images carry an unused PyGObject without its pycairo dependency;
# pip skips the uninstall on images without it.
RUN test -n "${PIP_PACKAGES}" \
    && python3 -m pip install --no-cache-dir ${PIP_PACKAGES} \
    && python3 -m pip uninstall --yes pygobject \
    && python3 -m pip check

LABEL org.opencontainers.image.title="asr-cuda"
