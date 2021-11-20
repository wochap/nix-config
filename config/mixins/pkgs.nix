{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; };
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    environment.sessionVariables = {
      NNN_TRASH = "1";
    };
    environment.systemPackages = with pkgs; [
      # TOOLS
      bc # calculator cli
      busybox
      cached-nix-shell # fast nix-shell scripts
      devour # swallow
      dex # execute DesktopEntry files
      dnsutils # test dns
      dos2unix # convert line breaks DOS - mac
      evtest # input debugging
      ffmpeg-full # music/video codecs?
      git
      glxinfo # opengl utils
      gnumake # make
      gpp # decrypt
      inxi # check compositor running
      jq # JSON
      killall
      libva-utils # verifying VA-API
      lsof # print port process
      manpages
      mkcert # create certificates (HTTPS)
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      ngrok # expose web server
      nix-prefetch-git # get fetchgit hashes
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      unzip
      usbutils # lsusb, for android development
      vdpauinfo # verifying VDPAU
      vim
      wget
      zip
      # base-devel

      # 7w7
      # metasploit
      nmap
      tightvnc

      # DE
      hunspell # dictionary for document programs
      hunspellDicts.en-us
      pavucontrol # audio settings gui

      # DE CLI
      gitAndTools.gh
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      pamixer # audio cli
      playerctl # media player cli
      ranger # file manager CLI
      systemd

      # APPS CLI
      stripe-cli
      speedread
      #dogecoin

      # APPS
      bitwarden
      brave
      discord
      betterdiscordctl
      dmenu
      filelight # view disk usage
      gparted
      insomnia
      nitrogen # wallpaper manager
      postman
      qbittorrent
      robo3t
      screenkey # show key pressed
      simplenote
      slack
      sublime3 # text editor
      tty-clock
      zoom-us
      # antimicroX
      # teamviewer
      # mysql-workbench

      # Themes
      capitaine-cursors
      hicolor-icon-theme
      papirus-icon-theme
    ] ++ [
      localPkgs.bigsur-cursors
    ] ++ (if (isWayland) then [
      pkgs.egl-wayland
      (pkgs.google-chrome.override {
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
      google-chrome
    ]);
  };
}
