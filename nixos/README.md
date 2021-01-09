# NixOS

## Getting started

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation)
1. Setup `nixos-hardware`
  ```
  $ sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
  $ sudo nix-channel --update
  ```
  Source: https://github.com/NixOS/nixos-hardware
1. Clone into `~/dev/nix-config`
1. Rebuild nixos with the machine's specific config, for example, heres's a rebuild for `mbp`
  ```
  $ NIX_PATH=$NIX_PATH:nixos-config=/home/<user_name>/dev/nix-config/nixos/devices/mbp.nix sudo nixos-rebuild switch -I nixos-config=/home/<user_name>/dev/nix-config/nixos/devices/mbp.nix
  ```
  Source: https://www.reddit.com/r/NixOS/comments/ec3je7/managing_configurationnix_and_homenix/

## References

* https://nixos.wiki/wiki/Home_Manager