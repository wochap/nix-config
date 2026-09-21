ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Keep the Qwen image's CUDA-enabled PyTorch installation. pip only adds the
# missing Community-1 runtime and leaves an already compatible torch in place.
# The base image carries an unused PyGObject without its pycairo dependency.
RUN python3 -m pip install --no-cache-dir "pyannote.audio==4.0.4" "protobuf<7" \
    && python3 -m pip uninstall --yes pygobject \
    && python3 -m pip check

LABEL org.opencontainers.image.title="qwen3-asr-diarization"
