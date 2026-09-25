# Container arguments and image build shared by asr-transcribe and asr-video.

# ROCm's PyTorch exposes AMD GPUs through the CUDA API, so both accelerators
# use the same device string.
asr_device="cuda:0"

read -r -a asr_gpu_device_list <<<"$ASR_GPU_DEVICES"
gpu_args=()
for asr_device_spec in "${asr_gpu_device_list[@]}"; do
  gpu_args+=("--device=$asr_device_spec")
done
if [[ $ASR_ACCELERATOR == rocm ]]; then
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
  "--env=ASR_DEVICE=$asr_device"
  "--env=ASR_DTYPE=$ASR_DTYPE"
  "--env=ASR_BATCH_SIZE=$ASR_BATCH_SIZE"
  "--env=ASR_BACKEND=$ASR_BACKEND"
)
if [[ -n $ASR_HSA_OVERRIDE_GFX_VERSION ]]; then
  gpu_args+=("--env=HSA_OVERRIDE_GFX_VERSION=$ASR_HSA_OVERRIDE_GFX_VERSION")
fi

# Pass the adapter's model pins into the container and mount the adapter.
read -r -a asr_revision_vars <<<"$ASR_REVISION_VARS"
for asr_revision_var in "${asr_revision_vars[@]}"; do
  gpu_args+=("--env=$asr_revision_var")
done
gpu_args+=("--volume=$ASR_ADAPTER:/opt/asr/adapter.py:ro")

# Model cache shared by all runs of the selected backend.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/asr/$ASR_BACKEND"
mkdir -p "$cache_dir"

# Succeed when every listed file, relative to the model cache, exists. An
# empty list never counts as cached.
files_cached() {
  (($#)) || return 1
  local cached_file
  for cached_file in "$@"; do
    [[ -e $cache_dir/$cached_file ]] || return 1
  done
}

# Build the local inference image on first use. Commands that run an upstream
# image receive an empty context and build nothing.
ensure_image() {
  [[ -n $ASR_IMAGE_CONTEXT ]] || return 0
  podman image exists "$ASR_IMAGE" && return 0
  echo "Building the pinned $ASR_BACKEND inference image (first run only)" >&2
  local build_args=() build_arg
  while IFS= read -r build_arg; do
    [[ -z $build_arg ]] || build_args+=(--build-arg "$build_arg")
  done <<<"$ASR_IMAGE_BUILD_ARGS"
  podman build --pull=missing "${build_args[@]}" \
    --tag "$ASR_IMAGE" "$ASR_IMAGE_CONTEXT"
}
