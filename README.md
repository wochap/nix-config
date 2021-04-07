# My NixOS configuration

![](https://i.imgur.com/vYt3wyj.jpg)

Hardware drivers are managed by [NixOS](https://nixos.org/) config files.
Apps and dotfiles are managed by [home-manager](https://github.com/nix-community/home-manager).

`NixOS` and `home-manager` config files are merged.

## Install NixOS

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation) and reboot.

    The minimun config is to have: `git`, `videoDrivers`, `desktopManager.xterm.enable = true;`, `internet setup`

    **NOTE:** Run `sudo nixos-install` without root user (sudo su)
1. Reboot and connect to wifi/ethernet
    If `ping google.com` doesn't work, try updating your DNS
    ```
    $ vim /etc/resolv.conf
    # add `nameserver 8.8.8.8` to `/etc/resolv.conf`
    ```
    Next commands will work if you enabled `networking.wireless.enable = true;`
    ```
    $ wpa_passphrase '<SSID>' '<passphrase>' | tee /etc/wpa_supplicant.conf
    $ wpa_supplicant -c /etc/wpa_supplicant.conf -i <interface> -B
    ```
1. Login with root user and clone into `~/nix-config`
    ```
    $ git clone https://github.com/wochap/nix-config.git ~/nix-config
    ```
1. Rebuild nixos with the machine's specific config, for example, heres's a rebuild for my `desktop`
    ```
    $ NIXOS_CONFIG=~/nix-config/devices/desktop.nix nixos-rebuild switch
    ```
    Addional notes: https://www.reddit.com/r/NixOS/comments/ec3je7/managing_configurationnix_and_homenix/
1. Set password for new user `gean`
    ```
    $ passwd gean
    ```

## Setup NixOS

1. Disable IPv6 in the NetworkManager Applet/Tray icon
1. Setup betterlockscreen (required for xorg config)
    ```
    $ betterlockscreen -u ~/Pictures/backgrounds/default.jpeg
    ```
1. Sync `vscode`, `firefox`, `chrome`
1. `desktop` config is optimized for 4k displays, for other sizes, you should update:
    For XORG:

    - fonts.fontconfig.dpi
    - services.xserver.dpi
    - Polybar bar variables (height, font size, etc)
    - BSPWM gaps?
    - Dunst styles?
    - Rofi styles?
    - Alttab args?
    - Powermenu styles?
    - Eww widgets styles?

    For Wayland:
    - WIP
1. Setup gnome calendar and geary
    ```
    $ env WEBKIT_DISABLE_COMPOSITING_MODE=1 gnome-control-center online-accounts
    ```
1. ~[Setup Thunderbird](https://www.lifewire.com/how-to-sync-google-calendar-with-thunderbird-4691009)~
1. Copy `.ssh` folder to `/home/gean/.ssh`
    ```
    $ ssh-keygen -m PEM -t rsa -b 4096 -C "email@email.com"
    $ chmod 600 ~/.ssh/*
    $ ssh-add <PATH_TO_PRIVATE_KEY>
    ```
    https://www.freecodecamp.org/news/how-to-manage-multiple-ssh-keys/
1. Fish setup
    ```
    # install fisher
    $ curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
    $ fisher install edouard-lopez/ayu-theme.fish
    $ set --universal ayu_variant mirage && ayu_load_theme
    ```
1. Setup [Flatpak](https://flatpak.org/setup/NixOS/)
    ```
    $ sudo flatpak override com.stremio.Stremio --env=QT_AUTO_SCREEN_SCALE_FACTOR=0
    $ sudo flatpak override com.stremio.Stremio --env=QT_SCALE_FACTOR=1.5
    $ sudo flatpak override com.stremio.Stremio --env=QT_FONT_DPI=144
    $ sudo flatpak override com.stremio.Stremio --env=XCURSOR_SIZE=40
    $ sudo flatpak --user override com.stremio.Stremio --filesystem=/home/gean/.icons/:ro
    ```
1. Setup [Lorri](https://github.com/target/lorri)
    ```
    $ direnv allow
    ```
1. [Monitor setup](https://http.download.nvidia.com/XFree86/Linux-x86/325.15/README/xconfigoptions.html) for nvidia cards

    ```
    # Show external monitor
    $ nvidia-settings --assign "CurrentMetaMode=DP-0: 3840x2160_60 @3840x2160 +2880+0 {ViewPortIn=3840x2160, ViewPortOut=3840x2160+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}, DP-2: 1920x1080_144 @1920x1080 +0+0 {ViewPortIn=2880x1620, ViewPortOut=2880x1620+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}"

    # Show only primary monitor
    $ nvidia-settings --assign "CurrentMetaMode=DP-0: 3840x2160_60 @3840x2160 +0+0 {ViewPortIn=3840x2160, ViewPortOut=3840x2160+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}"
    ```

1. Monitor setup with [xrandr](https://wiki.archlinux.org/index.php/HiDPI#Side_display)

    If panning is incorrect and you have NVIDIA, try toggling [adding 1px to the panning width](https://askubuntu.com/questions/853048/xrandr-adds-weird-virtual-screen-size-and-panning).

    ```
    # Show external monitor
    xrandr --dpi 144 \
      --output DP-0 --mode 3840x2160 --rate 60 --pos 2880x0 --primary \
      --output DP-2 --mode 1920x1080 --rate 144 --pos 0x0 --scale 1.5x1.5 --panning 2880x1620

    xrandr --dpi 144 \
      --output DP-0 --mode 3840x2160 --rate 60 --pos 2880x0 --primary \
      --output DP-2 --off
    ```

## Development Workflow

```
# Create shell.nix

$ lorri init
$ direnv allow
```

## Whats out of the box

1. Script for using phone webcam
    ```
    $ run-videochat -i <ip> -v
    ```

## Keybindings

The keybindings for bspwm are controlled by another program called sxhkd.

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>F1</kbd> | Reloads sxhkd |
| <kbd>Super</kbd> + <kbd>v</kbd> | Show clipboard |
| <kbd>Super</kbd> + <kbd>c</kbd> | Show calculator |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Opens terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Opens power menu |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Opens run launcher (rofi) |
| <kbd>Super</kbd> + <kbd>Print</kbd> | Take fullscreen screenshoot |
| <kbd>Super</kbd> + <kbd>w</kbd> | Closes window with focus |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd> | Kills window with focus |
| <kbd>Super</kbd> + <kbd>m</kbd> | Alternate between the tiled and monocle layout |
| <kbd>Super</kbd> + <kbd>/</kbd> | Show available keybindings |

Window state and flags

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>y</kbd> | Send the newest marked node to the newest preselected node |
| <kbd>Super</kbd> + <kbd>t</kbd> | Set window state to tiled |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>t</kbd> | Set window state to pseudo-tiled |
| <kbd>Super</kbd> + <kbd>s</kbd> | Set window state to floating |
| <kbd>Super</kbd> + <kbd>f</kbd> | Toggle window fullscreen state |
| <kbd>Super</kbd> + <kbd>m</kbd> | Set window flag to marked |
| <kbd>Super</kbd> + <kbd>x</kbd> | Set window flag to locked |
| <kbd>Super</kbd> + <kbd>y</kbd> | Set window flag to sticky |
| <kbd>Super</kbd> + <kbd>z</kbd> | Set window flag to private |

Preselection

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>h-j-k-l</kbd> | Preselect left-bottom-top-right positions for new window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>1-9</kbd> | Preselect the ratio for new window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Space</kbd> | Cancel preselection for the focused window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Cancel preselection for the focused desktop. |

Focus and swap

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Left Click</kbd> | Swap window |
| <kbd>Super</kbd> + <kbd>`</kbd> | Rotate focused windows |
| <kbd>Super</kbd> + <kbd>p</kbd> | Focus parent window |
| <kbd>Super</kbd> + <kbd>b</kbd> | Focus brother window |
| <kbd>Super</kbd> + <kbd>,</kbd> | Focus first window |
| <kbd>Super</kbd> + <kbd>.</kbd> | Focus second window |
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

Apps

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>l</kbd> | Lock screen |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>c</kbd> | Color picker |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>f</kbd> | Opens file manager |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>s</kbd> | Takes screenshoot (flameshot) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> ; <kbd>f</kbd> | Open firefox |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> ; <kbd>c</kbd> | Open chrome |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>t</kbd> | Opens terminal (kitty) |

Kitty keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Enter</kbd> | Opens new window |
| <kbd>Ctrl</kbd> + <kbd>l</kbd> | Cycle layouts (change layout) |
| <kbd>Ctrl</kbd> + <kbd>`</kbd> | Cycle focused window (swap) |
| <kbd>Ctrl</kbd> + <kbd>[</kbd> | Focus next window |
| <kbd>Ctrl</kbd> + <kbd>]</kbd> | Focus previous window |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Reset window |
| <kbd>Ctrl</kbd> + <kbd>k</kbd> | Clear window |
| <kbd>Ctrl</kbd> + <kbd>f</kbd> | Search |

Dunst keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Esc</kbd> | Show previous notification |

Firefox keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>.</kbd> ; <kbd>1</kbd> | Open google container |

## Troubleshooting

1. [Check packages size](https://nixos.wiki/wiki/Nix_command/path-info)

    ```
    $ nix path-info -rSh /run/current-system | sort -nk2
    ```

1. Fix flickering on nvidia cards
    - Open `Nvidia X Server Settings`.
    - In `OpenGL Settings` uncheck `Allow Flipping`.
    - In `XScreen0` > `X Server XVideo Settings` > `Sync to this display device` select your monitor.

1. Fix screen tearing on nvidia cards
    - Buy AMD GPU
    - FYI: ForceFullCompositionPipeline fix tearing but increase latency

* Check if picom is running

    ```
    $ inxi -Gxx | grep compositor
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

* [Wifi keeps connecting and disconnecting](https://unix.stackexchange.com/questions/588333/networkmanager-keeps-connecting-and-disconnecting-how-can-i-fix-this)

    Disable ipv6 connection.

* Test polybar themes

    ```
    $ killall polybar
    $ polybar main --config=/home/gean/nix-config/devices/config/users/config/dotfiles/polybar/main.ini -r
    ```

* Copy installed icons unicode

    `E8E4` is the unicode.

    ```
    $ bash
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

* Get key actual name

    ```
    $ xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
    ```

* [Cannot add google account in gnome > online accounts](https://github.com/NixOS/nixpkgs/issues/32580)
  In gmail settings, enable IMAP

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
* https://awesomeopensource.com/projects/nixos

### Rice resources

* https://fontawesome.com/cheatsheet
* https://fontdrop.info/
* https://coderwall.com/p/dedqca/argb-colors-in-android
* https://github.com/zodd18/Horizon
* https://www.iconfinder.com/search/?q=F028
* https://www.online-toolz.com/tools/text-unicode-entities-convertor.php
* https://www.reddit.com/r/firefox/comments/786dr7/how_do_i_identify_firefox_ui_elements/

### Others

* [Learn nix](https://nixcloud.io/tour/?id=3)
* https://nixos.wiki/wiki/Home_Manager
* https://superuser.com/questions/603528/how-to-get-the-current-monitor-resolution-or-monitor-name-lvds-vga1-etc
* https://nixos.org/manual/nix/stable/#use-as-a-interpreter
