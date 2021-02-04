# My NixOS configuration

![](https://i.imgur.com/UDOGx6L.jpg)

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
1. Setup wallpaper (required for xorg config)
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
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Quits bspwm |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd> | Closes window with focus |
| <kbd>Super</kbd> + <kbd>m</kbd> | Alternate between the tiled and monocle layout |

Window state and flags

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>y</kbd> | Send the newest marked node to the newest preselected node |
| <kbd>Super</kbd> + <kbd>t</kbd> | Set window state to tiled |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>t</kbd> | Set window state to pseudo-tiled |
| <kbd>Super</kbd> + <kbd>s</kbd> | Set window state to floating |
| <kbd>Super</kbd> + <kbd>f</kbd> | Set window state to fullscreen |
| <kbd>Super</kbd> + <kbd>m</kbd> | Set window flag to marked |
| <kbd>Super</kbd> + <kbd>x</kbd> | Set window flag to locked |
| <kbd>Super</kbd> + <kbd>y</kbd> | Set window flag to sticky |
| <kbd>Super</kbd> + <kbd>z</kbd> | Set window flag to private |

Focus and swap

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>j</kbd> | Switches focus between windows in the stack, going down |
| <kbd>Super</kbd> + <kbd>k</kbd> | Switches focus between windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>h</kbd> | Switches focus between windows in the stack, going left |
| <kbd>Super</kbd> + <kbd>l</kbd> | Switches focus between windows in the stack, going right |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd> | Rotates the windows in the stack, going down|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Rotates the windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>h</kbd> | Rotates the windows in the stack, going left |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>l</kbd> | Rotates the windows in the stack, going right |

Workspaces

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Left</kbd> | Switches to left workspace |
| <kbd>Super</kbd> + <kbd>Right</kbd> | Switches to right workspace |
| <kbd>Super</kbd> + <kbd>o</kbd> | Focus older window in the focus history |
| <kbd>Super</kbd> + <kbd>i</kbd> | Focus newer window in the focus history |
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch focus to workspace (1-9) |
| <kbd>Super</kbd> + <kbd>shift</kbd> + <kbd>1-9</kbd> | Send focused window to workspace (1-9) |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>shift</kbd> + <kbd>1-9</kbd> | Send window and switch to workspace (1-9) |

Resize windows

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Left Click</kbd> | Move window |
| <kbd>Super</kbd> + <kbd>Right Click</kbd> | Resize window |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>j</kbd> | Expand window, going down |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>k</kbd> | Expand window, going up |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>h</kbd> | Expand window, going left |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>l</kbd> | Expand window, going right |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd> | Contract window, going down |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Contract window, going up |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>h</kbd> | Contract window, going left |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>l</kbd> | Contract window, going right |

Apps

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>e</kbd> | Opens file manager (thunar) |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Opens terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Opens run launcher (rofi) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>s</kbd> | Takes screenshoot (flameshot) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> | Open firefox |

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
$ sudo chmod 600 ~/.ssh
$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_rsa
$ ssh-add -K
```

* Macbook Pro wifi

Create wpa conf before rebuild switch.

* [Fix firefox right click](https://www.reddit.com/r/i3wm/comments/88k0yt/right_mouse_btn_instantly_clicks_first_option_in/)

  Add padding to menu.

* Firefox doesnt load some websites

Enable DNS over HTTPS

* Change partition flags

```
$ parted /dev/sda
$ p
$ set 3 boot
```

## TODO

* Setup SSH github
* Setup theme for rofi, polybar, bspwm

## Inspiration

* https://github.com/JorelAli/nixos
* https://github.com/nrdxp/nixflk/tree/template
* https://github.com/kampka/nix-packages

## To learn

* https://www.secjuice.com/wayland-vs-xorg/

## Rice resources

* https://fontawesome.com/cheatsheet
