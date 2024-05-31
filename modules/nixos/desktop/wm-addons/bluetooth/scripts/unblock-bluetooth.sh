#!/usr/bin/env bash

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
  rfkill unblock bluetooth
fi
