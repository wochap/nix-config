# Personal NixOS configuration

[NixOS](https://nixos.org/) and [home-manager](https://github.com/nix-community/home-manager) config files are merged.

## DWL

![](https://i.imgur.com/TmgUC5J.jpg)
![](https://i.imgur.com/jBtseU6.jpg)

## Installaion

### Install NixOS

1. Follow the [manual](https://nixos.org/manual/nixos/stable/) and install NixOS with any desktop environment and reboot.

1. Update the generated nixos configuration in `/etc/nixos/configuration.nix`.

   The new configuration must have: user configuration, `flakes` enabled, `cachix` (optional), `git`, `git-crypt`, internet setup, `firewall` disabled

   Check the [configuration.nix](configuration-example.nix) example

### Install host config

Reboot into NixOS, login with the user you created

1. Connect to internet

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

1. Use local cachix, if you have 2 machines using the same nix config/channels (optional)

   ```
   # Run on another machine, with nixos installed
   $ nix-serve -p 8080

   # On current/new machine, test
   $ curl http://192.168.x.x:8080/nix-cache-info
   ```

   On the current/new machine, update `nix.settings.substituters` config, add `http://192.168.x.x:8080`, then restart

1. Clone this repository into `/home/<username>/.config/nix-config`

   ```
   $ git clone https://github.com/wochap/nix-config.git ~/.config/nix-config
   ```

1. Rebuild nixos with the host's specific config, for example, heres's a rebuild for my `gdesktop`

   **WARNING:** First `nixos-rebuild` with device config can take several hours, maybe you want to disable some modules

   ```
   # Go to nix-config folder
   $ cd /home/<username>/.config/nix-config
   $ nixos-rebuild boot --flake .#gdesktop
   # or if you want to switch to a specialisation
   # $ nixos-rebuild switch --flake .#gdesktop --specialisation hyprland-specialisation
   ```

   Reboot so changes take effect

   **NOTE:** If you encounter an error related to `home-manager`, it is likely due to a file collision, and you will need to remove a file. You can identify which files are in conflict with the following command: `systemctl status home-manager-<username>.service`. After resolving all the collisions, you can restart the `home-manager-<username>.service`.

1. Set password for new user `<username>` if you haven't
   ```
   # for example
   $ passwd gean
   ```

### Post install

1. Install ssh keys

   Copy `.ssh` backup folder to `/home/<username>/.ssh`

   ```
   $ chmod 600 ~/.ssh/*
   $ ssh-add <PATH_TO_PRIVATE_KEY>
   ```

   https://www.freecodecamp.org/news/how-to-manage-multiple-ssh-keys/

1. Unlock secrets folder

   Copy `git-crypt-key` backup

   ```
   $ cd /home/<username>/.config/nix-config
   $ git-crypt unlock /path/to/git-crypt-key
   ```

1. Install gpg keys

   ```
   $ gpg --import private.key
   ```

1. Enable autologin (optional)

   ```sh
   $ sudo touch /etc/security/autologin.conf
   ```

1. Setup Syncthing (http://localhost:8384)
1. Setup desktop wallpaper (optional)
   ```
   $ swww img ~/Pictures/backgrounds/<IMAGE_NAME>
   ```
1. Setup [Neovim](https://github.com/wochap/nvim) configuration
1. Setup qt look and feel
   Open `Qt5 Settings` and update theme and icons
   - icon theme: Tela-catppuccin_mocha-dark
   - color scheme: Catppuccin-Mocha-Mauve
   - style: Lightly
   - change font size to 10
1. Setup betterdiscord (optional)
   ```
   $ betterdiscordctl install
   ```
   enable theme from discord > betterdiscordctl settings
1. Enable WebRTC PipeWire support in chrome (wayland only)

   Go to chrome://flags/ and enable `WebRTC PipeWire support`

1. Sync `vscode`, `firefox`, `chrome` (optional)

1. Setup mail

   Generate [App passwords](https://support.google.com/accounts/answer/185833?hl=en) in [Google Account settings](https://myaccount.google.com/u/1/apppasswords)
   Copy App password (16 digits) to secrets/mail/<EMAIL>

1. Setup calendar

   A browser should open automatically asking for google credentials, otherwise run:

   ```sh
   $ vdirsyncer discover
   $ touch ~/.config/remind/remind.rem
   ```

1. [Waydroid](https://nixos.wiki/wiki/WayDroid) (optional)
1. [Flatpak](https://nixos.wiki/wiki/Flatpak) (optional)

1. Setup steam (optional)

   Run steam, login, setup proton.

## Upgrating NixOS

Update inputs on `flake.nix`, then:

```sh
$ cd /home/<username>/.config/nix-config
$ nix flake update --recreate-lock-file
$ sudo nixos-rebuild boot --flake .#gdesktop
```

## Development Workflow

- Setup a project with [nix-direnv](https://github.com/nix-community/nix-direnv)

  ```
  $ nix flake new -t github:nix-community/nix-direnv ./
  $ direnv allow
  # update flake.nix
  ```

## Troubleshooting

- Galaxy Buds

  - Connecting
    - Disconnect the Galaxy Buds case from the power source
    - Close the Galaxy Buds case
    - Open the Galaxy Buds case
    - Pair the Galaxy Buds (only required for the first time)
    - Repeat the process until the Galaxy Buds connect via Bluetooth
    - Once connected via Bluetooth, open the Galaxy Buds Client
  - Best audio profiles
    - Best audio output: High Fidelity Playback (A2DP Sink, codec AAC)
    - Worst output but allows input: Headset Head Unit (HSP/HFP, codec mSBC)

- Chrome like apps with blank screen or vanishing text on scroll

  Clear `GPUCache`, in `~/.config/google-chrome/ShaderCache`

  source: https://github.com/electron/electron/issues/40366
  source: https://discussion.fedoraproject.org/t/chromium-based-browsers-display-garbled-web-pages-after-mesa-is-updated/83438

- Slow zsh startup

  ```
  # print all zsh scripts that are being loaded
  $ exec -l zsh --sourcetrace
  ```

- Fix Virtual Machine Manager `network default is not active` error

  ```
  $ sudo virsh net-start default
  $ sudo virsh net-autostart default
  ```

- Fix [bootloader](https://nixos.wiki/wiki/Bootloader)

- Read and write NTFS partitions

  disable fast startup in windows

- [Search a package version in nixpkgs](https://lazamar.co.uk/nix-versions/)

- Generate Nix fetcher calls from repository URLs

  ```sh
  $ nurl https://github.com/nix-community/patsh v0.2.0 2>/dev/null
  ```

- Inspect systemctl services

  ```sh
  $ systemctl cat --user swayidle.service
  ```

- Reload .desktop files

  ```sh
  $ nix shell nixpkgs#desktop-file-utils -c update-desktop-database -v ~/.local/share/applications
  ```

- No wifi device at startup

  ```
  $ nmcli r wifi on
  ```

- Sync Bluetooth for dualboot Linux and Windows

  ```
  # on windows, turn off `fast startup``
  # mount your disk with windows, then:
  $ sudo bt-dualboot --sync-all --backup
  ```

- No bluetooth device at startup

  ```
  $ sudo rfkill unblock bluetooth
  ```

- [Bluetooth sound glitches](https://wiki.archlinux.org/title/bluetooth_headset#Connecting_works,_but_there_are_sound_glitches_all_the_time)

- Clear /nix/store

  ```
  $ nix-collect-garbage -d
  $ sudo nix-collect-garbage -d
  ```

- [Delete nixos system profile](https://www.reddit.com/r/NixOS/comments/ekryty/help_deleting_old_profiles/)

  ```
  # delete everything on
  $ /nix/var/nix/profiles/system-profiles/*

  # Clear store and rebuild
  ```

- [Check packages size](https://nixos.wiki/wiki/Nix_command/path-info)

  ```
  $ nix path-info -rSh /run/current-system | sort -nk2
  ```

- Firefox doesnt load some websites

  Enable DNS over HTTPS

- [Wifi keeps connecting and disconnecting](https://unix.stackexchange.com/questions/588333/networkmanager-keeps-connecting-and-disconnecting-how-can-i-fix-this)

  Disable ipv6 connection.

  ```sh
  # run the following to disable ipv6
  $ sudo sysctl net.ipv6.conf.all.disable_ipv6=1
  ```

- Copy installed icons unicode

  `E8E4` is the unicode.

  ```
  $ echo -ne "\uE8E4" | xclip -selection clipboard
  $ echo -ne "\ue92a" | wl-copy
  ```

- Transform svg icons to png

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

- Get key terminal code

  ```sh
  $ kitten show_key -m kitty
  $ kitty +kitten show_key
  $ showkey -a
  ```

- Get key actual name

  ```
  $ xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
  ```

- [Cannot add google account in gnome > online accounts](https://github.com/NixOS/nixpkgs/issues/32580)

  In gmail settings, enable IMAP

- Create udev rule

  ```sh
  # monitor uevent
  $ udevadm monitor --property

  # print devices ids (vendor, product, etc)
  $ lsusb

  # get env values
  $ udevadm info -q all -n /dev/input/eventX

  # get attr values
  $ udevadm info -n /dev/input/eventX --attribute-walk
  ```

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

- https://bennymeg.github.io/ngx-fluent-ui/
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
