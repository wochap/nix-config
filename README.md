# My NixOS configuration

![](https://i.imgur.com/HMMdWey.jpg)
![](https://i.imgur.com/RxL9gjb.jpg)

Hardware drivers are managed by [NixOS](https://nixos.org/) config files.
WM, Dotfiles are managed by [home-manager](https://github.com/nix-community/home-manager).

`NixOS` and `home-manager` config files are merged.

## Install vanilla NixOS

1. Install NixOS following the [manual](https://nixos.org/manual/nixos/stable/index.html#ch-installation) and reboot.

   The initial config must have: `user config`, `flakes`, `cachix`, `git`, `videoDrivers`, `internet setup`

   Initial [configuration.nix](configuration-example.nix) example

   **NOTE:** Run `sudo nixos-install`

1. Extra steps for MacBook Pro 11,5 (optional)

   To enable Intel GPU, you must install rEFInd and enable some options...

   ```sh
   sudo mkdir -p /boot/EFI/boot/
   sudo cp /boot/EFI/boot/bootx64.efi /boot/EFI/boot/bootx64.efi.bak
   sudo cp "$(nix-build '<nixpkgs>' --no-out-link -A 'refind')/share/refind/refind_x64.efi" /boot/EFI/boot/bootx64.efi

   sudo nix-shell -p efibootmgr
   cd $(nix-build '<nixpkgs>' --no-out-link -A 'refind')
   ./bin/refind-install
   ```

   Install [rEFInd-catppuccin](https://github.com/catppuccin/refind)
   ~~Install [rEFInd-minimal](https://github.com/evanpurkhiser/rEFInd-minimal)~~

   Install [enable gpu-switch on rEFInd](https://github.com/0xbb/gpu-switch#macbook-pro-113-and-115-notes)

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

   **IMPORTANT:** On clean install, update/add harware-configuration.nix in this repository

   **NOTE:** Env vars are required on first install https://github.com/NixOS/nixpkgs/issues/97433#issuecomment-689554709

   **WARNING:** First `nixos-rebuild` with device config can take several hours, maybe you want to disable some features

   ```
   # Go to nix-config folder
   $ cd /home/gean/nix-config
   $ NIXOS_INSTALL_BOOTLOADER=1 sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER nixos-rebuild boot --flake .#desktop
   # Reboot
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
   [Disable startup sound](https://gist.github.com/0xbb/ae298e2798e1c06d0753)
   ```
   $ ln -s ~/nix-config/modules/mbpfan/dotfiles/mbpfan.conf /etc/mbpfan.conf
   ```
1. Setup Syncthing (http://localhost:8384)
1. Setup backgrounds
   ```
   $ ln -s ~/Sync/backgrounds ~/Pictures/backgrounds
   ```
1. Setup [NeoVim](https://github.com/wochap/nvim), with ansible
1. Disable IPv6 in the NetworkManager Applet/Tray icon
1. Setup betterdiscord (optional)
   ```
   $ betterdiscordctl install
   ```
1. Enable WebRTC PipeWire support in chrome (wayland only)

   Go to chrome://flags/ and enable `WebRTC PipeWire support`
1. Sync `vscode`, `firefox`, `chrome` (optional)

1. Setup calendar

   A browser should open automatically asking for google credentials, otherwise run:
   ```
   $ vdirsyncer discover
   ```

1. [Waydroid](https://nixos.wiki/wiki/WayDroid)
1. [Flatpak](https://nixos.wiki/wiki/Flatpak)

1. Steam
   Run steam, login, setup proton.
1. ~~Setup [Flatpak](https://flatpak.org/setup/NixOS/)~~

   ```
   $ sudo flatpak override com.stremio.Stremio --env=QT_AUTO_SCREEN_SCALE_FACTOR=0
   $ sudo flatpak override com.stremio.Stremio --env=QT_SCALE_FACTOR=1.5
   $ sudo flatpak override com.stremio.Stremio --env=QT_FONT_DPI=144
   $ sudo flatpak override com.stremio.Stremio --env=XCURSOR_SIZE=40
   $ sudo flatpak --user override com.stremio.Stremio --filesystem=/home/gean/.icons/:ro
   ```

## Upgrating NixOS

Update inputs on `flake.nix`, then:

```sh
$ cd /home/gean/nix-config
$ nix flake update --recreate-lock-file
$ sudo nixos-rebuild boot --flake .#dekstop
```

## Development Workflow

1. Setup a project with [nix-direnv]()

   ```
   $ nix flake new -t github:nix-community/nix-direnv ./
   $ direnv allow
   # update flake.nix
   ```

## Tools

1. Script for using phone webcam
   ```
   $ run-videochat -i <ip> -v
   ```

## Troubleshooting

* No wifi device at startup

```
$ nmcli r wifi on
```

* Blackscreen on macbook pro

Run the following and restart

```
$ sudo gpu-switch -i
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
