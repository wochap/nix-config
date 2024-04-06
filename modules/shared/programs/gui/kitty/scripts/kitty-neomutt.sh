#!/usr/bin/env bash

echo "$@" | xargs -I {} kitty --class kitty-neomutt --title neomutt -e sh -c "neomutt {}"
