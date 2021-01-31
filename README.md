# My NixOS configuration

Hardware drivers are managed by [NixOS](https://nixos.org/) config files.
Apps and dotfiles are manager by [home-manager](https://github.com/nix-community/home-manager).

`NixOS` and `home-manager` config files are merged.

## Setup NixOS

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation) and reboot.

    **NOTE:** Run `sudo nixos-install` without root user (sudo su)
1. Reboot and connect to wifi/eth
    ```
    $ vim /etc/resolv.conf
    # add `nameserver 8.8.8.8` to `/etc/resolv.conf`
    ```
    Source: https://www.reddit.com/r/NixOS/comments/ec3je7/managing_configurationnix_and_homenix/
    ```
    $ wpa_passphrase '<SSID>' '<passphrase>' | tee /etc/wpa_supplicant.conf
    $ wpa_supplicant -c /etc/wpa_supplicant.conf -i <interface> -B
    ```
1. Login with root user and clone into `~/nix-config`
    ```
    $ git clone https://github.com/wochap/nix-config.git ~/nix-config
    ```
1. Rebuild nixos with the machine's specific config, for example, heres's a rebuild for `vb`
    ```
    $ NIXOS_CONFIG=~/nix-config/devices/vb.nix nixos-rebuild switch
    ```
    Addional notes: https://www.reddit.com/r/NixOS/comments/ec3je7/managing_configurationnix_and_homenix/
1. Set password for new user `gean`
    ```
    $ passwd gean
    ```
1. Setup wallpaper (required)
    ```
    $ git clone https://github.com/elementary/wallpapers.git
    $ wal -i <path_to_wallpaper>
1. Setup `bspwm` worspaces (optional)
    ```
    # Show available monitors
    $ xrandr
    # Modify bspwm config in `nix-config`
    ```

## Keybindings (defined by sxhkd)

The keybindings for bspwm are controlled by another program called sxhkd.

| Keybinding | Action |
| :--- | :--- |
| <kbd>Alt</kbd> + <kbd>Space</kbd> | Opens run launcher (rofi) |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Opens terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd> | Closes window with focus |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Quits bspwm |
| <kbd>Super</kbd> + <kbd>j</kbd> | Switches focus between windows in the stack, going down |
| <kbd>Super</kbd> + <kbd>k</kbd> | Switches focus between windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd> | Rotates the windows in the stack, going down|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Rotates the windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>t</kbd> | Set window state to tiled |
| <kbd>Super</kbd> + <kbd>s</kbd> | Set window state to pseudo-tiled |
| <kbd>Super</kbd> + <kbd>f</kbd> | Set window state to floating |
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch focus to workspace (1-9) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1-9</kbd> | Sends focused window to workspace (1-9) |

## Resources

* [Learn nix](https://nixcloud.io/tour/?id=3)
* https://nixos.wiki/wiki/Home_Manager
* https://superuser.com/questions/603528/how-to-get-the-current-monitor-resolution-or-monitor-name-lvds-vga1-etc
* https://gitlab.com/dwt1/dotfiles

## Troubleshooting

* Check if picom is running

```
$ inxi -Gxx | grep compositor
```

* Setup ssh

```
$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_rsa
$ ssh-add -K
```

## TODO

* Setup SSH github
* Setup theme for rofi, polybar, bspwm
