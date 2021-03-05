#!/usr/bin/env sh

# source https://github.com/NixOS/nixpkgs/issues/15531
gnome_online_accounts_path=$(nix eval nixpkgs.gnome3.gnome_online_accounts.outPath)
# remove double quotes
gnome_online_accounts_path="${gnome_online_accounts_path%\"}"
gnome_online_accounts_path="${gnome_online_accounts_path#\"}"
command="${gnome_online_accounts_path}/libexec/goa-daemon --replace"
$command &
