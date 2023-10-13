{ config, pkgs, lib, inputs, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        # TOOLS
        libinput
        libinput-gestures
        xorg.xev # get key actual name

        # TOOLS (wayland)
        wev # get key actual name

        # CLI TOOLS
        _custom.advcpmv # cp and mv with progress bar
        acpi
        acpitool
        cached-nix-shell # fast nix-shell scripts
        coreutils-full # a lot of commands
        devour # swallow
        dex # execute DesktopEntry files (xdg/autostart)
        dmidecode
        dnsutils # test dns
        efivar
        evtest # input debugging
        ffmpegthumbnailer
        glxinfo # opengl utils
        graphicsmagick
        heimdall # reset samsung ROM
        ifuse # mount ios
        inotify-tools # c module
        inxi # check compositor running
        libimobiledevice # mount ios
        libva-utils # verifying VA-API
        notify-desktop # test notifications
        pciutils # lspci and others commands
        pulsemixer
        slop # region selection
        usbutils # lsusb, for android development
        vdpauinfo # verifying VDPAU
        vulkan-tools
        wirelesstools
        xorg.xdpyinfo
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
        ueberzugpp
        tty-clock

        # APPS GUI
        dmenu
        nyxt # browser
        skypeforlinux
        zoom-us
        # antimicroX
        # mysql-workbench
        # teamviewer

        # Electron apps
        bitwarden
        brave
        element-desktop-wayland
        figma-linux
        unstable.insomnia
        microsoft-edge
        notion-app-enhanced
        postman
        prevstable-chrome.google-chrome # HACK: fix https://github.com/NixOS/nixpkgs/issues/244742
        prevstable-chrome.netflix
        simplenote
        slack
        whatsapp-for-linux
      ];
    };
  };
}
