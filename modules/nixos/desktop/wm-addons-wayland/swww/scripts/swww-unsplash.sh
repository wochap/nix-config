#!/usr/bin/env bash

declare -A topicIdByType
topicIdByType=(
  ["wallpapers"]="bo8jQKTaE0Y"
  ["current_events"]="BJJMtteDJA4"
  ["act_for_nature"]="wnzpLxs0nQY"
  ["nature"]="6sMVjTLSkeQ"
  ["travel"]="Fzo3zuOHN6w"
)

# UNSPLASH_API_KEY=${UNSPLASH_API_KEY:-your_unsplash_api_key}
UNSPLASH_API_KEY=$(cat ~/nix-config/secrets/unsplash/gean.marroquin@gmail.com/access_key)
download_path=$(mktemp -d)
width="3840" # value between 1920 and 3840, snap up to nearest 240 for improved caching
topic_id=${topicIdByType["wallpapers"]}

# Fetch a random image URL from the Unsplash API
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
