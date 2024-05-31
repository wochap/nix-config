#!/usr/bin/env bash

# Kill previous tmux session
if tmux has-session -t se 2>/dev/null; then
  echo "Killing previous tmux session: se"
  tmux kill-session -t se
fi
if tmux has-session -t se-editors 2>/dev/null; then
  echo "Killing previous tmux session: se-editors"
  tmux kill-session -t se-editors
fi

# Focus DWL tag 2
ydotool key 125:1 3:1 3:0 125:0

echo "Start docker services"
docker start viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1
trap 'docker stop viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1' exit

# wait for docker services to be ready
sleep 3

# Start new foot terminal with tmux session
echo "Start new tmux session"
footclient tmux new-session zsh -i -c "tmuxinator start se" &
footclient tmux new-session zsh -i -c "tmuxinator start se-editors" &

# Keep the script running
while true; do
  sleep 1
done
