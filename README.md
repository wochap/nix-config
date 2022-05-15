# My NixOS configuration

![](https://i.imgur.com/Fuj0NXH.jpg)

Hardware drivers are managed by [NixOS](https://nixos.org/) config files.
WM, Dotfiles are managed by [home-manager](https://github.com/nix-community/home-manager).

`NixOS` and `home-manager` config files are merged.

## Install vanilla NixOS

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation) and reboot.

   The initial config must have: `user config`, `flakes`, `cachix`, `git`, `videoDrivers`, `internet setup`

   **NOTE:** Run `sudo nixos-install`

   Initial [configuration.nix](configuration-example.nix) example

   Extra steps for MacBook Pro 11,5 (to enable Intel GPU)

   ```sh
   sudo mkdir -p /boot/EFI/boot/
   sudo cp /boot/EFI/boot/bootx64.efi /boot/EFI/boot/bootx64.efi.bak
   sudo cp "$(nix-build '<nixpkgs>' --no-out-link -A 'refind')/share/refind/refind_x64.efi" /boot/EFI/boot/bootx64.efi

   cd $(nix-build '<nixpkgs>' --no-out-link -A 'refind')
   sudo nix-shell -p efibootmgr
   refind-install
   ```

   Install [rEFInd-minimal](https://github.com/evanpurkhiser/rEFInd-minimal)

## Install device config

You probably want to press `Ctrl + Alt + F1`

1. Reboot into vanilla NixOS and connect to wifi/ethernet

   ```
   # The following commands will work if you enabled `networking.networkmanager.enable = true;`
   $ nmtui
   $ ping google.com
   ```

   If `ping google.com` doesn't work, try updating your DNS

   ```
   $ vim /etc/resolv.conf
   # add `nameserver 8.8.8.8` to `/etc/resolv.conf`
   ```

1. Login with root user and clone into `~/nix-config`
   ```
   $ git clone https://github.com/wochap/nix-config.git ~/nix-config
   ```
1. Rebuild nixos with the device's specific config, for example, heres's a rebuild for my `desktop`

   **IMPORTANT:** On clean install, update harware-configuration.nix in this repository

   **NOTE:** Env vars are required on first install https://github.com/NixOS/nixpkgs/issues/97433#issuecomment-689554709

   **WARNING:** First `nixos-rebuild` with device config can take several hours

   ```
   # Go to nix-config folder
   $ cd /home/gean/nix-config
   $ NIXOS_INSTALL_BOOTLOADER=1 sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER nixos-rebuild boot --flake .#desktop --impure
   # Reboot
   # $ sudo nixos-rebuild boot -p sway --flake .#desktop-sway --impure
   ```

1. Set password for new user `gean`
   ```
   $ passwd gean
   ```

## Setup NixOS

1. Use local cachix (optional)
   ```
   # Run on local machine with nixos installed
   $ nix-serve -p 8080

   # On new machine, test
   $ curl http://192.168.x.x:8080/nix-cache-info
   ```
   On the new machine, update `nix.binaryCaches`, add `http://192.168.x.x:8080`

1. Copy `.ssh` backup folder to `/home/gean/.ssh`
   ```
   $ ssh-keygen -m PEM -t rsa -b 4096 -C "email@email.com"
   $ chmod 600 ~/.ssh/*
   $ ssh-add <PATH_TO_PRIVATE_KEY>
   ```
   https://www.freecodecamp.org/news/how-to-manage-multiple-ssh-keys/
1. Copy `git-crypt-key` backup, unlock secrets
   ```
   $ git-crypt unlock /path/to/git-crypt-key
   ```
1. Import gpg keys
   ```
   $ gpg --import private.key
   ```
1. If you are using nixos on mbp
   ```
   $ ln -s ~/nix-config/config/mixins/mbpfan/dotfiles/mbpfan.conf /etc/mbpfan.conf
   ```
1. Setup Syncthing (http://localhost:8384)
1. Setup backagrounds
   ```
   $ ln -s ~/Sync/backgrounds ~/Pictures/backgrounds
   ```
1. Setup [NeoVim](https://github.com/wochap/nvim), with ansible
1. Disable IPv6 in the NetworkManager Applet/Tray icon
1. Setup betterdiscord (optional)
   ```
   $ betterdiscordctl install
   ```
1. Add wallpapers to `~/Pictures/backgrounds/`
1. Setup lock wallpaper (required for xorg config)
   ```
   $ convert -resize $(xdpyinfo | grep dimensions | cut -d\  -f7 | cut -dx -f1) ~/Pictures/backgrounds/default.jpg ~/Pictures/backgrounds/lockscreen.jpg
   ```
1. Sync `vscode`, `firefox`, `chrome` (optional)
1. Scaling

   Xorg is optomized for 100%, 150%, 200%

   - DPI is controlled by autorandr, it also restart the following apps
     - Rofi
     - Polybar
     - Dunst
     - BSPWM gaps and borders
   - GTK apps settings are controlled by xsettingsd
   - Non GTK apps settings are controlled by xrdb

1. ~~Setup gnome calendar and geary (optional)~~
   ```
   $ env WEBKIT_DISABLE_COMPOSITING_MODE=1 gnome-control-center online-accounts
   ```
1. ~~[Setup Thunderbird](https://www.lifewire.com/how-to-sync-google-calendar-with-thunderbird-4691009)~~
1. ~~Setup [Flatpak](https://flatpak.org/setup/NixOS/)~~

   ```
   $ sudo flatpak override com.stremio.Stremio --env=QT_AUTO_SCREEN_SCALE_FACTOR=0
   $ sudo flatpak override com.stremio.Stremio --env=QT_SCALE_FACTOR=1.5
   $ sudo flatpak override com.stremio.Stremio --env=QT_FONT_DPI=144
   $ sudo flatpak override com.stremio.Stremio --env=XCURSOR_SIZE=40
   $ sudo flatpak --user override com.stremio.Stremio --filesystem=/home/gean/.icons/:ro
   ```

1. ~~[Monitor setup](https://http.download.nvidia.com/XFree86/Linux-x86/325.15/README/xconfigoptions.html) for nvidia cards~~

   ```
   # Show external monitor
   $ nvidia-settings --assign "CurrentMetaMode=DP-0: 3840x2160_60 @3840x2160 +2880+0 {ViewPortIn=3840x2160, ViewPortOut=3840x2160+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}, DP-2: 1920x1080_144 @1920x1080 +0+0 {ViewPortIn=2880x1620, ViewPortOut=2880x1620+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}"

   # Show only primary monitor
   $ nvidia-settings --assign "CurrentMetaMode=DP-0: 3840x2160_60 @3840x2160 +0+0 {ViewPortIn=3840x2160, ViewPortOut=3840x2160+0+0, ForceCompositionPipeline=Off, ForceFullCompositionPipeline=Off}"
   ```

1. ~~Monitor setup with [xrandr](https://wiki.archlinux.org/index.php/HiDPI#Side_display)~~

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

## Upgrating NixOS

Update inputs on `flake.nix`, then:

```sh
$ cd /home/gean/nix-config
$ nix flake update --recreate-lock-file
$ sudo nixos-rebuild switch --flake .#dekstop --impure
```

## Development Workflow

1. Setup [Lorri](https://github.com/nix-community/lorri)

   In the project folder:

   ```
   # Create shell.nix

   $ lorri init
   $ direnv allow
   ```

   [Fix XDG_DATA_DIRS reset](https://github.com/target/lorri/issues/496)
   Debug initialization

   ```
   $ lorri shell
   $ nix-shell
   ```

## Tools

1. Script for using phone webcam
   ```
   $ run-videochat -i <ip> -v
   ```

## Troubleshooting

* Slow firefox with nvidia drivers

  Use wayland (EGL) or

   ```sh
   # Go to https://www.vsynctester.com/
   $ __GL_HWSTATE_PER_CTX=2 __GL_yieldFunctionWaitForGpu=5 firefox
   # or, in about:config
   gfx.x11-egl.force-enabled true
   gfx.webrender.software false
   ```

* Clear /nix/store

   ```
   $ nix-collect-garbage -d
   $ sudo nix-collect-garbage -d
   ```

* [Delete nixos system profile](https://www.reddit.com/r/NixOS/comments/ekryty/help_deleting_old_profiles/)

   ```
   # delete everything on
   $ /nix/var/nix/profiles/system-profiles/*

   # Clear store and rebuild
   ```

* [Check packages size](https://nixos.wiki/wiki/Nix_command/path-info)

   ```
   $ nix path-info -rSh /run/current-system | sort -nk2
   ```

* Fix flickering on nvidia cards?

   - Open `Nvidia X Server Settings`.
   - In `OpenGL Settings` uncheck `Allow Flipping`.
   - In `XScreen0` > `X Server XVideo Settings` > `Sync to this display device` select your monitor.

* Fix screen tearing on nvidia cards

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
   $ echo -ne "\uE8E4" | xclip -selection clipboard
   $ echo -ne "\ue92a" | wl-copy
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

- https://github.com/phenax/nixos-dotfiles
- https://gitlab.com/dwt1/dotfiles
- https://github.com/JorelAli/nixos
- https://github.com/nrdxp/nixflk/tree/template
- https://github.com/kampka/nix-packages
- https://github.com/sgraf812/.nixpkgs
- https://www.reddit.com/r/NixOS/comments/k7e9sg/newbie_desktop_nixos_setup_for_developer/

### To learn

- https://www.secjuice.com/wayland-vs-xorg/
- https://discourse.nixos.org/t/how-to-set-the-xdg-mime-default/3560
- https://awesomeopensource.com/projects/nixos

### Rice resources

- https://fontawesome.com/cheatsheet
- https://fontdrop.info/
- https://coderwall.com/p/dedqca/argb-colors-in-android
- https://github.com/zodd18/Horizon
- https://www.iconfinder.com/search/?q=F028
- https://www.online-toolz.com/tools/text-unicode-entities-convertor.php
- https://www.reddit.com/r/firefox/comments/786dr7/how_do_i_identify_firefox_ui_elements/

### Others

- [Learn nix](https://nixcloud.io/tour/?id=3)
- https://nixos.wiki/wiki/Home_Manager
- https://superuser.com/questions/603528/how-to-get-the-current-monitor-resolution-or-monitor-name-lvds-vga1-etc
- https://nixos.org/manual/nix/stable/#use-as-a-interpreter
