#!/usr/bin/env bash

# Copy all .env files in ~/Projects to ~/tmp/Projects
find ~/Projects -maxdepth 2 -type d -execdir test -f {}/.env \; -exec sh -c 'echo {} | sed "s/Projects/tmp\/Projects/" | xargs mkdir -p; cp `echo {} | sed "s/$/\/\.env/"` `echo {} | sed "s/$/\/\.env/" | sed "s/Projects/tmp\/Projects/"`' \;
