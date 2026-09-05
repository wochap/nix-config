#!/usr/bin/env bash

set -euo pipefail

for command_name in rtk openspec; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'new-project: required command not found: %s\n' "$command_name" >&2
    exit 1
  fi
done

# RTK's Codex integration creates the shared RTK instructions and references
# them from AGENTS.md.
rtk init --codex

openspec init --tools qwen,codex,pi,claude

gitignore_entries=(
  'openspec/changes/archive'
  '.rtk'
  'AGENTS.md'
  'RTK.md'
  '.codex'
  '.qwen'
  '.direnv'
  '.pi'
)

missing_entries=()
for entry in "${gitignore_entries[@]}"; do
  if [[ ! -f .gitignore ]] || ! grep -Fqx -- "$entry" .gitignore; then
    missing_entries+=("$entry")
  fi
done

if ((${#missing_entries[@]} > 0)); then
  if [[ -s .gitignore ]]; then
    printf '\n' >>.gitignore
  fi
  printf '%s\n' "${missing_entries[@]}" >>.gitignore
fi
