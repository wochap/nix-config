#!/usr/bin/env bash

tofi-drun --config "$HOME/.config/tofi/one-line" --drun-launch=false | xargs -I {} uwsm-app -- {}
