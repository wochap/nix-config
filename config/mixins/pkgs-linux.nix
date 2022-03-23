{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages {
    pkgs = pkgs;
    lib = lib;
  };
  isWayland = config._displayServer == "wayland";

  ani-cli = pkgs.writeShellScriptBin "ani-cli"
    (builtins.readFile "${inputs.ani-cli}/ani-cli");
  mangaflix = pkgs.writeShellScriptBin "mangaflix"
    (builtins.readFile "${inputs.flix-tools}/ManganatoFlix/mangaflix");
  piratebayflix = pkgs.writeShellScriptBin "piratebayflix"
    (builtins.readFile "${inputs.flix-tools}/PirateBayFlix/piratebayflix");
  fontpreview-ueberzug = pkgs.writeShellScriptBin "fontpreview-ueberzug"
    (builtins.readFile "${inputs.fontpreview-ueberzug}/fontpreview-ueberzug");
in {
  config = {
    environment.systemPackages = with pkgs;
      [
        # TOOLS
        acpitool
        coreutils-full # a lot of commands
        devour # swallow
        dex # execute DesktopEntry files (xdg/autostart)
        dmidecode
        dnsutils # test dns
        evtest # input debugging
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
        # metasploit
        nmap
        # tightvnc

        # DE
        hunspell # dictionary for document programs
        hunspellDicts.en-us
        pulseaudio

        # DE CLI
        systemd
        # pamixer # audio cli

        # APPS CLI
        fontpreview-ueberzug

        # APPS
        dfeet
        dmenu
        filelight # view disk usage
        gparted
        pinta
        qbittorrent
        skypeforlinux

        # localPkgs.nsxiv
        # antimicroX

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
