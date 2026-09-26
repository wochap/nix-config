# Container arguments and image build shared by the GPU container tools. The
# NixOS modules concatenate this prelude in front of each tool's launcher and
# set the AI_* variables through aiLib.mkGpuEnv.

read -r -a ai_gpu_device_list <<<"$AI_GPU_DEVICES"
gpu_args=()
for ai_device_spec in "${ai_gpu_device_list[@]}"; do
  gpu_args+=("--device=$ai_device_spec")
done
if [[ $AI_ACCELERATOR == rocm ]]; then
  # Keep the caller's supplementary groups so /dev/kfd stays reachable on
  # hosts where it belongs to the render group rather than being world
  # readable.
  gpu_args+=(--group-add=keep-groups)
  if [[ -n $AI_HSA_OVERRIDE_GFX_VERSION ]]; then
    gpu_args+=("--env=HSA_OVERRIDE_GFX_VERSION=$AI_HSA_OVERRIDE_GFX_VERSION")
  fi
fi

# Hardening and resource limits every inference container gets: no
# capabilities or privilege escalation, a read-only rootfs with a bounded
# tmpfs at /tmp, and capped process count and shared memory.
sandbox_args=(
  --cap-drop=all
  --security-opt=no-new-privileges
  --read-only
  --pids-limit=2048
  "--shm-size=$AI_SHM_SIZE"
  "--tmpfs=/tmp:rw,nosuid,nodev,size=$AI_TMP_SIZE"
)

# No network, and Hugging Face libraries told to use only local files.
offline_args=(
  --network=none
  --env=HF_HUB_OFFLINE=1
  --env=TRANSFORMERS_OFFLINE=1
)

# Build the local inference image on first use. An image run as pulled from
# upstream has an empty context and builds nothing.
ensure_image() {
  [[ -n $AI_IMAGE_CONTEXT ]] || return 0
  podman image exists "$AI_IMAGE" && return 0
  echo "Building the pinned $AI_IMAGE_LABEL image (first run only; this can take a while)" >&2
  local build_args=() build_arg
  while IFS= read -r build_arg; do
    [[ -z $build_arg ]] || build_args+=(--build-arg "$build_arg")
  done <<<"$AI_IMAGE_BUILD_ARGS"
  podman build --pull=missing "${build_args[@]}" \
    --tag "$AI_IMAGE" "$AI_IMAGE_CONTEXT"
}
