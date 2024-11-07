#!/usr/bin/env bash

workspace=$(gum choose --height 5 --no-show-help {all,'layout-editor',surveys})

if [ -z "$workspace" ]; then
  exit 0
fi

function cleanup() {
  # Kill previous tmux session
  if tmux has-session -t se 2>/dev/null; then
    echo "Killing tmux session: se"
    tmux kill-session -t se
  fi
  if tmux has-session -t se-editors 2>/dev/null; then
    echo "Killing tmux session: se-editors"
    tmux kill-session -t se-editors
  fi

  echo "Stopping docker services"
  docker stop viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1

  # wait for docker services stop
  sleep 3
}

function start() {
  echo "Starting docker services"
  docker start viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1

  # wait for docker services to be ready
  sleep 3

  # Focus DWL tag 2
  # 125 = logo
  # 3 = 2
  ydotool key 125:1 3:1 3:0 125:0

  # Change to monocle layout
  # 125 = logo
  # 3 = 2
  # ydotool

  # Start new foot terminal with tmux session
  echo "Starting tmux session: se"
  footclient --app-id=footclient-se tmux new-session zsh -i -c "tmuxinator start se workspace=$workspace" &
  echo "Starting tmux session: se-editors"
  footclient --app-id=footclient-se-editors tmux new-session zsh -i -c "tmuxinator start se-editors workspace=$workspace" &
}

cleanup

start
trap 'cleanup' exit

# Keep the script running
while true; do
  sleep 1
done
