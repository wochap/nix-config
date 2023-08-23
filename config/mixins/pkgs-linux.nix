{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages { inherit pkgs lib; };
  isWayland = config._displayServer == "wayland";

  fontpreview-ueberzug = pkgs.writeShellScriptBin "fontpreview-ueberzug"
    (builtins.readFile "${inputs.fontpreview-ueberzug}/fontpreview-ueberzug");
in {
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
      libinput
      libinput-gestures
      xorg.xev # get key actual name

      # CLI TOOLS
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
      localPkgs.advcpmv # cp and mv with progress bar
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      slop # region selection
      usbutils # lsusb, for android development
      vdpauinfo # verifying VDPAU
      vulkan-tools
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
      dmenu
      nyxt # browser
      qutebrowser # browser
      skypeforlinux
      zoom-us
      # antimicroX
      # localPkgs.nsxiv
      # mysql-workbench
      # teamviewer

      # Electron apps
      bitwarden
      brave
      figma-linux
      prevstable-chrome.google-chrome
      microsoft-edge
      notion-app-enhanced
      postman
      simplenote
      slack
      insomnia
      whatsapp-for-linux
    ];
  };
}
