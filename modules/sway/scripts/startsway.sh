#!/usr/bin/env bash

# first import environment variables from the login manager
systemctl --user import-environment

# then start the service
exec systemctl --user start sway.service

