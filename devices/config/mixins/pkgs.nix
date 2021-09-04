{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; };
in
{
  config = {
    environment.sessionVariables = {
      NNN_TRASH = "1";
    };
    environment.systemPackages = with pkgs; [
      # TOOLS
      bc # calculator cli
      cached-nix-shell # fast nix-shell scripts
      dex # execute DesktopEntry files
      dnsutils # test dns
      dos2unix # convert line breaks DOS - mac
      evtest # input debugging
      ffmpeg-full # music/video codecs?
      fzf # fuzzy search
      git
      glxinfo # opengl utils
      gnumake # make
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
      unstable.devour # swallow
      unzip
      usbutils # lsusb, for android development
      vdpauinfo # verifying VDPAU
      vim
      wget
      zip
      # base-devel

      # 7w7
      metasploit
      nmap
      tightvnc

      # DE
      alacritty # terminal fallback
      hunspell # dictionary for document programs
      hunspellDicts.en-us
      mpv # video player
      pavucontrol # audio settings gui
      zathura # PDF viewer

      # DE CLI
      gitAndTools.gh
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      nnn # file manager CLI
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
      filelight # view disk usage
      gparted
      nitrogen # wallpaper manager
      postman
      qbittorrent
      screenkey # show key pressed
      simplenote
      slack
      unstable.google-chrome
      unstable.sublime3 # text editor
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
      localPkgs.zscroll # scroll text in shells
    ];
  };
}
