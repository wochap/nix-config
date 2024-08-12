#!/usr/bin/env bash

# UNSPLASH_API_KEY=${UNSPLASH_API_KEY:-your_unsplash_api_key}
UNSPLASH_API_KEY=$(cat ~/nix-config/secrets/unsplash/gean.marroquin@gmail.com/access_key)
download_path=$(mktemp -d)

declare -A topicIdByType
topicIdByType=(
  ["wallpapers"]="bo8jQKTaE0Y"
  ["current_events"]="BJJMtteDJA4"
  ["act_for_nature"]="wnzpLxs0nQY"
  ["nature"]="6sMVjTLSkeQ"
  ["travel"]="Fzo3zuOHN6w"
)
topic_id=${topicIdByType["wallpapers"]}

# Fetch a random image URL from the Unsplash API
width="3840"
response=$(curl -s -H "Authorization: Client-ID ${UNSPLASH_API_KEY}" \
  "https://api.unsplash.com/photos/random?topics=$topic_id&orientation=landscape&count=1")
slug=$(echo "${response}" | jq -r '.[].slug')
image_url=$(echo "${response}" | jq -r '.[].urls.raw')
image_link="${image_url}&q=85&w=${width}"
image_path="${download_path}/${slug}"

# Download the image
curl -o "${image_path}" "$image_link"
echo "Image downloaded as '${image_path}'"

# Change wallpaper
swww img "${image_path}"
