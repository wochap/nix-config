{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  isWayland = config._displayServer == "wayland";

  fontpreview-ueberzug = pkgs.writeShellScriptBin "fontpreview-ueberzug"
    (builtins.readFile "${inputs.fontpreview-ueberzug}/fontpreview-ueberzug");
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        # CLI TOOLS
        acpitool
        cached-nix-shell # fast nix-shell scripts
        coreutils-full # a lot of commands
        devour # swallow
        dex # execute DesktopEntry files (xdg/autostart)
        dmidecode
        dnsutils # test dns
        evtest # input debugging
        ffmpegthumbnailer
        glxinfo # opengl utils
        inotify-tools # c module
        inxi # check compositor running
        libva-utils # verifying VA-API
        notify-desktop # test notifications
        pciutils # lspci and others commands
        pulsemixer
        slop # region selection
        usbutils # lsusb, for android development
        vdpauinfo # verifying VDPAU
        wirelesstools
        # base-devel
        # busybox # a lot of commands but with less options/features
        # mpc_cli
        # mpd
        # mpd_clientlib # mpd module
        # procps

        # 7w7
        nmap
        # metasploit
        # tightvnc

        # DE CLI
        hunspell # dictionary for document programs
        hunspellDicts.en-us
        pulseaudio
        systemd
        # pamixer # audio cli

        # APPS CLI
        fontpreview-ueberzug
        tty-clock

        # APPS GUI
        dfeet # dbus gui
        dmenu
        filelight # view disk usage
        gparted
        nyxt # browser
        pinta
        qbittorrent
        qutebrowser # browser
        skypeforlinux
        sublime3 # text editor
        zoom-us
        # antimicroX
        # localPkgs.nsxiv
        # mysql-workbench
        # teamviewer

      ] ++ (if (isWayland) then [
        # Electron apps
        electron-stable.bitwarden
        electron-stable.brave
        electron-stable.insomnia
        electron-stable.postman
        electron-stable.simplenote
        electron-stable.slack
        (electron-stable.google-chrome.override {
          commandLineArgs = ''
            --enable-features=UseOzonePlatform \
            --ozone-platform=wayland \
            --ignore-gpu-blocklist \
            --enable-gpu-rasterization \
            --enable-zero-copy \
            --disable-gpu-driver-bug-workarounds \
            --enable-features=VaapiVideoDecoder
          '';
        })
      ] else [
        # Electron apps
        bitwarden
        brave
        google-chrome
        insomnia
        postman
        simplenote
        slack
        unstable.notion-app-enhanced
        whatsapp-for-linux
      ]);
  };
}
