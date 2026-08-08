#!/usr/bin/env bash

# prints the unread inbox mail count from the last 24 hours from the notmuch database
command -v notmuch >/dev/null 2>&1 || {
  echo 0
  exit 0
}

count=$(notmuch count 'tag:unread and tag:inbox and date:24h..' 2>/dev/null) || count=0
[[ "$count" =~ ^[0-9]+$ ]] || count=0
echo "$count"
