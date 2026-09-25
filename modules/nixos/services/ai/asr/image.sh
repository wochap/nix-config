# ASR container arguments shared by asr-transcribe and asr-video. The NixOS
# module puts ../lib/container.sh, which sets up gpu_args and ensure_image,
# in front of this script.

# ROCm's PyTorch exposes AMD GPUs through the CUDA API, so both accelerators
# use the same device string.
asr_device="cuda:0"

if [[ $AI_ACCELERATOR == rocm ]]; then
  # MIOpen writes its kernel databases under ~/.config by default, which the
  # read-only rootfs rejects. Keep them next to the model cache so compiled
  # kernels survive between runs.
  gpu_args+=(--env=MIOPEN_USER_DB_PATH=/root/.cache/miopen/db)
fi
gpu_args+=(
  "--env=ASR_DEVICE=$asr_device"
  "--env=ASR_DTYPE=$ASR_DTYPE"
  "--env=ASR_BATCH_SIZE=$ASR_BATCH_SIZE"
  "--env=ASR_ADAPTER=$ASR_ADAPTER"
)

# Pass the adapter's model pins into the container and mount the adapter.
read -r -a asr_revision_vars <<<"$ASR_REVISION_VARS"
for asr_revision_var in "${asr_revision_vars[@]}"; do
  gpu_args+=("--env=$asr_revision_var")
done
gpu_args+=("--volume=$ASR_ADAPTER_MODULE:/opt/asr/adapter.py:ro")

# Model cache shared by all runs of the selected adapter.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/asr/$ASR_ADAPTER"
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
