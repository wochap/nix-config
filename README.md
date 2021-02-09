# My NixOS configuration

![](https://i.imgur.com/e9813MH.jpg)

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
1. Copy `.ssh` folder
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
1. Fix flickering on nvidia cards
    - Open `Nvidia X Server Settings`.
    - In `OpenGL Settings` uncheck `Allow Flipping`.
    - In `X Server XVideo Settings` select your monitor.
1. Fix screen tearing on nvidia cards
    - Buy AMD GPU
    - FYI: ForceFullCompositionPipeline fix tearing but increase latency
1. [Fix firefox insta right click](https://gist.github.com/AntonFriberg/15bcd0dbfe7506a08e55fb2163644cc9)
1. Setup betterlockscreen (required for xorg config)
    ```
    $ betterlockscreen -u ~/Pictures/wallpapers/default.jpeg
    ```

## Keybindings

The keybindings for bspwm are controlled by another program called sxhkd.

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Opens power menu |
| <kbd>Super</kbd> + <kbd>q</kbd> | Closes window with focus |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd> | Kills window with focus |
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
| <kbd>Super</kbd> + <kbd>Left Click</kbd> | Swap window |
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

## Troubleshooting

* Check if picom is running

```
$ inxi -Gxx | grep compositor
```

* Setup ssh

```
$ sudo chmod 600 ~/.ssh
# $ eval $(ssh-agent)
# $ ssh-add ~/.ssh/id_rsa
$ ssh-add
```

* Macbook Pro wifi

Create wpa conf before rebuild switch.

* Firefox doesnt load some websites

Enable DNS over HTTPS

* Change partition flags

```
$ parted /dev/sda
$ p
$ set 3 boot
```

* (Wifi keeps connecting and disconnecting)[https://unix.stackexchange.com/questions/588333/networkmanager-keeps-connecting-and-disconnecting-how-can-i-fix-this]

Disable ipv6 connection.

* Test polybar themes

```
$ killall polybar
$ polybar main --config=/home/gean/nix-config/devices/config/users/config/dotfiles/polybar/main.ini -r
```

* Copy installed icons unicode

`E8E4` is the unicode.
```
$ echo -ne "\uE8E4" | xclip -selection clipboard
```

* Transform svg icons to png

```
$ for file in *.svg; do inkscape $file -o ${file%svg}png -h 128; done
```

```
#!/usr/bin/env bash

symlinks=$(find ./ -lname "*.svg");

for file in $symlinks; do
  linkpath=$(readlink $file);
  newlinkcontent=${linkpath/svg/png};
  newlinkpath=${file/svg/png};
  ln -sf $newlinkcontent $newlinkpath;
done
```

## Resources

### Inspiration

* https://github.com/phenax/nixos-dotfiles
* https://gitlab.com/dwt1/dotfiles
* https://github.com/JorelAli/nixos
* https://github.com/nrdxp/nixflk/tree/template
* https://github.com/kampka/nix-packages
* https://github.com/sgraf812/.nixpkgs
* https://www.reddit.com/r/NixOS/comments/k7e9sg/newbie_desktop_nixos_setup_for_developer/

### To learn

* https://www.secjuice.com/wayland-vs-xorg/
* https://discourse.nixos.org/t/how-to-set-the-xdg-mime-default/3560

### Rice resources

* https://fontawesome.com/cheatsheet
* https://fontdrop.info/
* https://coderwall.com/p/dedqca/argb-colors-in-android
* https://github.com/zodd18/Horizon
* https://www.iconfinder.com/search/?q=F028

### Others

* [Learn nix](https://nixcloud.io/tour/?id=3)
* https://nixos.wiki/wiki/Home_Manager
* https://superuser.com/questions/603528/how-to-get-the-current-monitor-resolution-or-monitor-name-lvds-vga1-etc
