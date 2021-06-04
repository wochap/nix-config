{ config, pkgs, lib, ... }:

let
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
      killall
      libva-utils # verifying VA-API
      lsof # print port process
      manpages
      mkcert # create certificates (HTTPS)
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      nix-prefetch-git # get fetchgit hashes
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      trash-cli # required by vscode
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
      kitty # terminal
      kmag # magnifying glass
      mpv # video player
      nitrogen # wallpaper manager
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
