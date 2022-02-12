{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; lib = lib; };
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
      ansible
      bc # calculator cli
      busybox
      cached-nix-shell # fast nix-shell scripts
      devour # swallow
      dex # execute DesktopEntry files (xdg/autostart)
      dmidecode
      dnsutils # test dns
      dos2unix # convert line breaks DOS - mac
      evtest # input debugging
      ffmpeg-full # music/video codecs?
      gecode
      git
      git-crypt
      glxinfo # opengl utils
      gnumake # make
      gpp # decrypt
      inotify-tools
      inxi # check compositor running
      jq # JSON
      killall
      libva-utils # verifying VA-API
      lm_sensors
      lsof # print port process
      manpages
      mkcert # create certificates (HTTPS)
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      ngrok # expose web server
      nix-prefetch-git # get fetchgit hashes
      nodePackages.node2nix
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      tldr
      unrar
      unzip
      urlscan
      usbutils # lsusb, for android development
      vdpauinfo # verifying VDPAU
      vim
      wget
      wirelesstools
      zip
      # base-devel

      # 7w7
      # metasploit
      nmap
      # tightvnc

      # DE
      hunspell # dictionary for document programs
      hunspellDicts.en-us
      pulseaudio

      # DE CLI
      gitAndTools.gh
      gotop # monitor system
      perl534Packages.WWWYoutubeViewer
      playerctl # media player cli
      systemd
      youtube-dl
      # pamixer # audio cli

      # APPS CLI
      stripe-cli
      speedread
      #dogecoin

      # APPS
      dmenu
      filelight # view disk usage
      gparted
      gpick
      nitrogen # wallpaper manager
      pinta
      qbittorrent
      screenkey # show key pressed
      skypeforlinux
      sublime3 # text editor
      tmux
      tty-clock
      zoom-us
      localPkgs.nsxiv
      # antimicroX
      # teamviewer
      # mysql-workbench

      # Themes
      capitaine-cursors

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
      insomnia
      postman
      simplenote
      slack
      google-chrome
    ]);
  };
}
