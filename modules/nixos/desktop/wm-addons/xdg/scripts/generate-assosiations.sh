#!/usr/bin/env bash

echo -e "$(xdg-list)" | while IFS= read -r line; do
  result=$(echo $line | awk -F':' '{print $1}' | xargs xdg-types)
  line_count=$(echo "$result" | wc -l)
  if [ "$line_count" -gt 1 ]; then
    printf "$result"
    printf "\n"
  fi
done
