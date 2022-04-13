#!/usr/bin/env bash

# Show scratchpad
yabai-focus.sh "kitty-scratch" "~/.config/kitty/scripts/kitty-scratch.sh"

# Run yarn commands
kitty @ --to unix:/tmp/kitty_scratch launch --tab-title=nd --type=tab --cwd ~/Projects/boc/nurse-disrupted/functions zsh -c 'firebase emulators:start --import ./emulator-data & zsh'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/admin zsh -c 'expo start --web'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/provider zsh -c 'expo start --web'
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/kiosk zsh -c "yarn start & zsh"
kitty @ --to unix:/tmp/kitty_scratch launch --cwd ~/Projects/boc/nurse-disrupted/kiosk zsh -c "zsh"
kitty @ --to unix:/tmp/kitty_scratch goto-layout Grid

# TODO: move to workspace
code ~/Projects/boc/nurse-disrupted
