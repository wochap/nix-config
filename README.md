# My NixOS configuration

Hardware drivers are managed by [NixOS](https://nixos.org/) config files.
Apps and dotfiles are manager by [home-manager](https://github.com/nix-community/home-manager).

`NixOS` and `home-manager` config files are merged.

## Setup NixOS

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation)
1. Clone into `~/dev/nix-config`
    ```
    $ git clone https://github.com/wochap/nix-config.git ~/dev/nix-config
    ```
1. Rebuild nixos with the machine's specific config, for example, heres's a rebuild for `vb` and `mbp`
    ```
    $ NIXOS_CONFIG=/root/nix-config/nixos/devices/vb.nix nixos-rebuild switch
    # or
    $ NIX_PATH=$NIX_PATH:nixos-config=/home/<user_name>/dev/nix-config/nixos/devices/mbp.nix sudo nixos-rebuild switch -I nixos-config=/home/<user_name>/dev/nix-config/nixos/devices/mbp.nix
    ```
    Source: https://www.reddit.com/r/NixOS/comments/ec3je7/managing_configurationnix_and_homenix/
1. Set password for new user `gean`
```
$ passwd gean
```
1. Setup `bspwm` worspaces
```
# Show available monitors
$ xrandr
# Modify bspwm config in dotfiles folder and rebuild
```

## Resources

* [Learn nix](https://nixcloud.io/tour/?id=3)
* https://nixos.wiki/wiki/Home_Manager
* https://superuser.com/questions/603528/how-to-get-the-current-monitor-resolution-or-monitor-name-lvds-vga1-etc

## TODO

* Setup ssh github
* Setup vscode + plugins
* Setup firefox + profile
* Setup theme for rofi, polybar, bspwm
* Setup sxhkd
* Setup web development (docker)    