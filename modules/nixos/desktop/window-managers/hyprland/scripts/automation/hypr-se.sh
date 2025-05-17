#!/usr/bin/env bash

function get_branch_info() {
  local path="$1"
  local dir_name
  dir_name=$(basename "$path")
  local branch
  branch=$(git -C "$path" rev-parse --abbrev-ref HEAD)
  echo "Current branch in '$dir_name' is '$branch'"
}

viz_omni_path="$HOME/Projects/se/viz-omni"
pearson_surveys_path="$HOME/Projects/se/pearson-surveys"
socialexplorer_surveys_path="$HOME/Projects/se/socialexplorer-surveys"
pearson_customs_path="$HOME/Projects/se/pearson-customs"
viz_websites_path="$HOME/Projects/se/viz-websites"
mapspice_ui_path="$HOME/Projects/se/mapspice-ui"
confirm_message=$(
  get_branch_info "$viz_omni_path"
  get_branch_info "$pearson_surveys_path"
  get_branch_info "$socialexplorer_surveys_path"
  get_branch_info "$pearson_customs_path"
  get_branch_info "$viz_websites_path"
  get_branch_info "$mapspice_ui_path"
  echo "Continue?"
)
confirm_branch=$(gum confirm --no-show-help "$confirm_message" && echo 1 || echo 0)

if [ "$confirm_branch" -eq 0 ]; then
  exit 0
fi

start_docker=$(gum confirm --no-show-help 'start docker?' && echo 1 || echo 0)
workspaces=$(gum choose --height 6 --no-show-help --no-limit {'layout-editor',microfrontends,charts,surveys} | paste -sd, -)

if [ -z "$workspaces" ]; then
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

  if [ $start_docker -eq 1 ]; then
    echo "Stopping docker services"
    docker stop viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1

    # grace time for docker services to stop
    # sleep 1

    echo -n "Waiting for PostgreSQL to stop..."
    while pg_isready -h localhost -p 5433 -U datahub -d datahub2_local -q; do
      echo -n "."
      sleep 0.1
    done
    echo -e "\nPostgreSQL has stopped!"
  fi
}

function start() {
  if [ $start_docker -eq 1 ]; then
    echo "Starting docker services"
    docker start viz-docker-viz-tile-delivery-1 viz-docker-viz-mongo-1 viz-docker-viz-elasticsearch-1 viz-docker-viz-redis-1 viz-docker-viz-minio-1 viz-docker-viz-postgis-1

    # grace time for docker services to start
    sleep 1

    # TODO: check for Elasticsearch?

    echo -n "Waiting for PostgreSQL to be ready..."
    while ! pg_isready -h localhost -p 5433 -U datahub -d datahub2_local -q; do
      echo -n "."
      sleep 0.1
    done
    echo -e "\nPostgreSQL is ready!"
  fi

  # Focus workspace 2
  hyprctl dispatch workspace 2

  # Change to monocle layout
  hyprland-monocle --start

  # Start new foot terminal with tmux session
  echo "Starting tmux session: se"
  footclient --app-id=footclient-se tmux new-session zsh -i -c "tmuxinator start se workspaces=$workspaces" &
  echo "Starting tmux session: se-editors"
  footclient --app-id=footclient-se-editors tmux new-session zsh -i -c "tmuxinator start se-editors workspaces=$workspaces" &
}

cleanup

start
trap 'cleanup' exit

# Keep the script running
while true; do
  sleep 1
done
