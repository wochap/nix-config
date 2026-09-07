#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: pdf-ingest setup
       pdf-ingest [--dpi DPI] [--min-dpi DPI] [--batch-size N] PDF [OUTPUT_DIR]

Options:
  --dpi DPI         Initial render resolution (default: 200)
  --min-dpi DPI     Lowest resolution used after CUDA OOM (default: 120)
  --batch-size N    Initial inference batch size (default: 1)
  --help, -h        Show this help
EOF
}

die() {
  echo "pdf-ingest: $*" >&2
  exit 2
}

if [[ ${1:-} == setup ]]; then
  (($# == 1)) || die "setup takes no arguments"
  echo "Pulling pinned PaddleOCR-VL offline image" >&2
  exec podman pull "$PDF_INGEST_IMAGE"
fi

dpi=200
min_dpi=120
batch_size=1
positional=()
while (($#)); do
  case "$1" in
  --dpi | --min-dpi | --batch-size)
    (($# >= 2)) || { usage; exit 2; }
    value=$2
    [[ $value =~ ^[1-9][0-9]*$ ]] || die "$1 must be a positive integer"
    case "$1" in
    --dpi) dpi=$value ;;
    --min-dpi) min_dpi=$value ;;
    --batch-size) batch_size=$value ;;
    esac
    shift 2
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  --*)
    usage
    exit 2
    ;;
  *)
    positional+=("$1")
    shift
    ;;
  esac
done

((${#positional[@]} >= 1 && ${#positional[@]} <= 2)) || { usage; exit 2; }
((min_dpi <= dpi)) || die "--min-dpi cannot exceed --dpi"

source_pdf=${positional[0]}
[[ -f $source_pdf ]] || die "input does not exist or is not a regular file: $source_pdf"
[[ ${source_pdf,,} == *.pdf ]] || die "input filename must end in .pdf"
mime=$(file --brief --mime-type -- "$source_pdf")
[[ $mime == application/pdf ]] || die "input is not a PDF (detected $mime)"
source_pdf=$(realpath "$source_pdf")

if ((${#positional[@]} == 2)); then
  output_dir=${positional[1]}
else
  source_base=$(basename "$source_pdf")
  output_dir="./${source_base%.*}"
fi

if [[ -e $output_dir && ! -d $output_dir ]]; then
  die "destination exists and is not a directory: $output_dir"
fi
mkdir -p -- "$output_dir"
output_dir=$(realpath "$output_dir")

probe_args=(probe --source "$source_pdf" --output "$output_dir" --dpi "$dpi" --min-dpi "$min_dpi" --batch-size "$batch_size" --image "$PDF_INGEST_IMAGE")
set +e
probe_output=$(python3 "$PDF_INGEST_PIPELINE" "${probe_args[@]}" 2>&1)
probe_status=$?
set -e
case $probe_status in
0)
  echo "pdf-ingest: matching document is already complete: $output_dir" >&2
  exit 0
  ;;
10)
  [[ -z $probe_output ]] || echo "$probe_output" >&2
  ;;
*)
  [[ -z $probe_output ]] || echo "$probe_output" >&2
  exit "$probe_status"
  ;;
esac

state_dir="$output_dir/.pdf-ingest-state"
mkdir -p -- "$state_dir"

container_args=(
  run
  --rm
  --pull=never
  --network=none
  --device=nvidia.com/gpu=all
  --cap-drop=all
  --security-opt=no-new-privileges
  --read-only
  --pids-limit=2048
  --shm-size=2g
  "--tmpfs=/tmp:rw,nosuid,nodev,size=4g"
  "--tmpfs=/root/.cache:rw,nosuid,nodev,size=512m"
  --env=PYTHONDONTWRITEBYTECODE=1
  --env=FLAGS_use_mkldnn=0
  --env=HF_HUB_OFFLINE=1
  --env=TRANSFORMERS_OFFLINE=1
  --env=PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
  --entrypoint=python3
  "--volume=$source_pdf:/input/source.pdf:ro"
  "--volume=$output_dir:/output:rw"
  "--volume=$PDF_INGEST_PIPELINE:/opt/pdf-ingest/pdf-ingest.py:ro"
)

echo "pdf-ingest: extracting $(basename "$source_pdf") at ${dpi} DPI (offline)" >&2
set +e
podman "${container_args[@]}" "$PDF_INGEST_IMAGE" \
  /opt/pdf-ingest/pdf-ingest.py ingest \
  --source /input/source.pdf \
  --source-name "$(basename "$source_pdf")" \
  --output /output \
  --dpi "$dpi" \
  --min-dpi "$min_dpi" \
  --batch-size "$batch_size" \
  --image "$PDF_INGEST_IMAGE"
status=$?
set -e
if ((status != 0)); then
  echo "pdf-ingest: extraction stopped; checkpoints were preserved" >&2
  printf 'Resume with: pdf-ingest --dpi %q --min-dpi %q --batch-size %q %q %q\n' \
    "$dpi" "$min_dpi" "$batch_size" "$source_pdf" "$output_dir" >&2
  exit "$status"
fi

if ! python3 "$PDF_INGEST_PIPELINE" "${probe_args[@]}" >/dev/null; then
  die "container exited successfully but the completed output failed validation; checkpoints were preserved"
fi

echo "pdf-ingest: document written to $output_dir" >&2
