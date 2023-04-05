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
      graphicsmagick
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

      # Electron apps
      bitwarden
      brave
      figma-linux
      google-chrome
      microsoft-edge
      notion-app-enhanced
      postman
      simplenote
      slack
      unstable.insomnia
      whatsapp-for-linux
    ];
  };
}
