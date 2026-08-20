#!/usr/bin/env bash

set -euo pipefail

KANSALLISGALLERIA_API_KEY=$(</run/secrets/personal-kansallisgalleria-token)
KANSALLISGALLERIA_ORIGIN="https://kokoelma.kansallisgalleria.fi"
download_path=$(mktemp -d)
trap 'rm -rf -- "$download_path"' EXIT

# Fetch copyright-free artworks that have an image.
response=$(curl --fail --silent --show-error \
  -X POST \
  -H "x-api-key: ${KANSALLISGALLERIA_API_KEY}" \
  -H "Content-Type: application/json" \
  --data '{"categoryId":"artwork","copyrightFree":true,"hasImage":true,"lang":"en"}' \
  "${KANSALLISGALLERIA_ORIGIN}/api/v1/search")

# Keep only results with a downloadable JPEG, then choose one at random.
image_count=$(jq '[.[] | select(any(.multimedia[]?; (.jpg // {}) | length > 0))] | length' <<<"$response")
if ((image_count == 0)); then
  echo "Kansallisgalleria returned no artworks with downloadable JPEG images" >&2
  exit 1
fi

image_index=$(shuf -i "0-$((image_count - 1))" -n 1)
artwork=$(jq -c \
  '[.[] | select(any(.multimedia[]?; (.jpg // {}) | length > 0))] | .[$index]' \
  --argjson index "$image_index" <<<"$response")

object_id=$(jq -r '.objectId' <<<"$artwork")
image_url=$(jq -r '
  [.multimedia[]?.jpg // {} | to_entries[] | select(.value | type == "string")]
  | max_by(.key | tonumber? // 0)
  | .value
' <<<"$artwork")
if [[ $image_url == /* ]]; then
  image_url="${KANSALLISGALLERIA_ORIGIN}${image_url}"
fi
image_tmp_path="${download_path}/${object_id}.jpg"

curl --fail --location --show-error -o "$image_tmp_path" "$image_url"
echo "Image downloaded as '${image_tmp_path}'"

# Approximate the artwork's dominant color from a reduced eight-color palette.
fill_color=$(magick "$image_tmp_path" \
  -alpha off \
  -resize 100x100 \
  -colors 8 \
  -depth 8 \
  -format %c histogram:info:- \
  | sort -nr \
  | sed -n '1{s/.*#\([[:xdigit:]]\{6\}\).*/\1ff/p;}')
fill_color=${fill_color:-000000ff}

# Change wallpaper.
image_path="${HOME}/Pictures/backgrounds/kansallisgalleria_wallpaper"
cp "$image_tmp_path" "$image_path"
awww img --resize fit --fill-color "$fill_color" "$image_path"
