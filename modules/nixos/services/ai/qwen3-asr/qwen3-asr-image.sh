# Container arguments and image build shared by qwen3-asr-transcribe and
# qwen3-asr-video.

# ROCm's PyTorch exposes AMD GPUs through the CUDA API, so both accelerators
# use the same device string.
qwen3_asr_device="cuda:0"

read -r -a qwen3_asr_gpu_device_list <<<"$QWEN3_ASR_GPU_DEVICES"
gpu_args=()
for qwen3_asr_device_spec in "${qwen3_asr_gpu_device_list[@]}"; do
  gpu_args+=("--device=$qwen3_asr_device_spec")
done
if [[ $QWEN3_ASR_ACCELERATOR == rocm ]]; then
  # Keep the caller's supplementary groups so /dev/kfd stays reachable on
  # hosts where it belongs to the render group rather than being world
  # readable.
  gpu_args+=(--group-add=keep-groups)
  # MIOpen writes its kernel databases under ~/.config by default, which the
  # read-only rootfs rejects. Keep them next to the model cache so compiled
  # kernels survive between runs.
  gpu_args+=(--env=MIOPEN_USER_DB_PATH=/root/.cache/miopen/db)
fi
gpu_args+=(
  "--env=QWEN3_ASR_DEVICE=$qwen3_asr_device"
  "--env=QWEN3_ASR_DTYPE=$QWEN3_ASR_DTYPE"
  "--env=QWEN3_ASR_BATCH_SIZE=$QWEN3_ASR_BATCH_SIZE"
)
if [[ -n $QWEN3_ASR_HSA_OVERRIDE_GFX_VERSION ]]; then
  gpu_args+=("--env=HSA_OVERRIDE_GFX_VERSION=$QWEN3_ASR_HSA_OVERRIDE_GFX_VERSION")
fi

# Build the local inference image on first use. Commands that run an upstream
# image receive an empty context and build nothing.
ensure_image() {
  [[ -n $QWEN3_ASR_IMAGE_CONTEXT ]] || return 0
  podman image exists "$QWEN3_ASR_IMAGE" && return 0
  echo "Building the pinned Qwen3-ASR inference image (first run only)" >&2
  local build_args=()
  [[ -z $QWEN3_ASR_IMAGE_BUILD_ARGS ]] || build_args+=(--build-arg "$QWEN3_ASR_IMAGE_BUILD_ARGS")
  podman build --pull=missing "${build_args[@]}" \
    --tag "$QWEN3_ASR_IMAGE" "$QWEN3_ASR_IMAGE_CONTEXT"
}

