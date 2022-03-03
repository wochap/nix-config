{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; lib = lib; };
  isWayland = config._displayServer == "wayland";

  ani-cli = pkgs.writeShellScriptBin "ani-cli" (builtins.readFile "${inputs.ani-cli}/ani-cli");
  mangaflix = pkgs.writeShellScriptBin "mangaflix" (builtins.readFile "${inputs.flix-tools}/ManganatoFlix/mangaflix");
  piratebayflix = pkgs.writeShellScriptBin "piratebayflix" (builtins.readFile "${inputs.flix-tools}/PirateBayFlix/piratebayflix");
in
{
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
      acpitool
      ansible
      aria
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
      ffmpegthumbnailer
      file
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
      openssl
      pciutils # lspci and others commands
      pulsemixer
      pup # parse html
      slop
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
      amfora
      gitAndTools.gh
      gotop # monitor system
      lynx
      systemd
      # pamixer # audio cli

      # APPS CLI
      ani-cli
      cbonsai
      piratebayflix
      speedread
      stripe-cli
      # mangaflix
      # unstable.nodePackages_latest.webtorrent-cli
      # dogecoin

      # APPS
      dmenu
      filelight # view disk usage
      gparted
      pinta
      qbittorrent
      skypeforlinux
      sublime3 # text editor
      tmux
      tty-clock
      zoom-us
      # localPkgs.nsxiv
      # antimicroX
      # teamviewer
      # mysql-workbench

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
