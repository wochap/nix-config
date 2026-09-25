# Container arguments and image build for pdf-ingest. This prelude is
# concatenated in front of pdf-ingest.sh by the NixOS module.

read -r -a pdf_ingest_gpu_device_list <<<"$PDF_INGEST_GPU_DEVICES"
gpu_args=()
for pdf_ingest_device_spec in "${pdf_ingest_gpu_device_list[@]}"; do
  gpu_args+=("--device=$pdf_ingest_device_spec")
done
if [[ $PDF_INGEST_ACCELERATOR == rocm ]]; then
  # Keep the caller's supplementary groups so /dev/kfd stays reachable on
  # hosts where it belongs to the render group rather than being world
  # readable.
  gpu_args+=(--group-add=keep-groups)
  # MIOpen writes its user kernel database under ~/.config and its compiled
  # kernel cache under ~/.cache; the Hugging Face libraries and Matplotlib
  # also cache under the home directory. All of that is rejected by the
  # read-only rootfs, so point it at the container's tmpfs. The model weights
  # are baked into the image and never go through HF_HOME.
  gpu_args+=(--env=MIOPEN_USER_DB_PATH=/tmp/miopen/db)
  gpu_args+=(--env=MIOPEN_CUSTOM_CACHE_DIR=/tmp/miopen/cache)
  gpu_args+=(--env=HF_HOME=/tmp/hf)
  gpu_args+=(--env=MPLCONFIGDIR=/tmp/matplotlib)
  if [[ -n $PDF_INGEST_HSA_OVERRIDE_GFX_VERSION ]]; then
    gpu_args+=("--env=HSA_OVERRIDE_GFX_VERSION=$PDF_INGEST_HSA_OVERRIDE_GFX_VERSION")
  fi
fi

# Build the local inference image on first use. An adapter that runs an
# upstream image passes an empty context and builds nothing.
ensure_image() {
  [[ -n $PDF_INGEST_IMAGE_CONTEXT ]] || return 0
  podman image exists "$PDF_INGEST_IMAGE" && return 0
  echo "Building the pinned $PDF_INGEST_ADAPTER_DISPLAY $PDF_INGEST_ACCELERATOR image (first run only; this downloads the model weights and takes a while)" >&2
  local build_args=()
  [[ -z $PDF_INGEST_IMAGE_BUILD_ARGS ]] || build_args+=(--build-arg "$PDF_INGEST_IMAGE_BUILD_ARGS")
  podman build --pull=missing "${build_args[@]}" \
    --tag "$PDF_INGEST_IMAGE" "$PDF_INGEST_IMAGE_CONTEXT"
}

