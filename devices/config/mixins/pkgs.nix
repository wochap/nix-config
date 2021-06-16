{ config, pkgs, lib, ... }:

let
  unstablePkgs = import (builtins.fetchTarball {
    url = https://github.com/nixos/nixpkgs/archive/2c2b33c326a3faf5dc86e373dfafe0dcf3eb5136.tar.gz;
    sha256 = "0wpfllarf1s0bbs85f9pa4nihf94hscpzvk5af4a1zxgq2l9c8r6";
  }) { config = config.nixpkgs.config; };
  localPkgs = import ../packages { pkgs = pkgs; };
in
{
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
      # base-devel
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
      trash-cli # required by vscode
      unstablePkgs.devour # swallow
      unzip
      vdpauinfo # verifying VDPAU
      vim
      wget
      zip

      # 7w7
      teamviewer
      nmap
      tightvnc
      metasploit
      teamviewer

      # APPS CLI
      gitAndTools.gh
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      ranger # file manager cli
      #dogecoin

      # DE
      feh # wallpaper manager
      hunspell # dictionary for document programs
      hunspellDicts.en-us
      hyper
      kitty # terminal
      kmag # magnifying glass
      mpv # video player
      nitrogen # wallpaper manager
      nnn # terminal file manager
      pamixer # audio cli
      pavucontrol # audio settings gui
      playerctl # media player cli
      systemd

      # APPS
      anki # mnemonic tool
      bitwarden
      brave
      deluge # torrent client
      discord
      etcher # create booteable usbs
      filelight # view disk usage
      google-chrome
      gparted
      mysql-workbench
      postman
      screenkey # show key pressed
      simplenote
      slack
      sublime3 # text editor
      sxiv # simple image viewer
      vscode
      zathura # PDF viewer
      zoom-us

      # APPS MEDIA
      inkscape # photo editor cli/gui
      kdeApplications.kdenlive # video editor
      nomacs # image viewer/editor
      obs-studio # video capture
      olive-editor
      openshot-qt # video editor

      # Themes
      adwaita-qt
      capitaine-cursors
      hicolor-icon-theme
      papirus-icon-theme

      # Themes settings
      qt5.qtgraphicaleffects # required by gddm themes
      qt5ct
    ] ++ [
      localPkgs.bigsur-cursors
      localPkgs.http-url-handler
      localPkgs.sddm-sugar-dark-greeter
      localPkgs.sddm-whitesur-greeter
      localPkgs.stremio
      localPkgs.zscroll # scroll text in shells
    ];
  };
}
