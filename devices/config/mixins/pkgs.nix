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
      dex # execute DesktopEntry files
      direnv # auto run nix-shell
      dos2unix # convert line breaks DOS - mac
      evtest # input debugging
      ffmpeg-full # music/video codecs?
      fzf # fuzzy search
      git
      glxinfo # opengl utils
      gnumake # make
      inxi # check compositor running
      killall
      libqalculate # rofi-calc dependency
      libva-utils # verifying VA-API
      manpages
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      trash-cli # required by vscode
      unzip
      vdpauinfo # verifying VDPAU
      vim
      wget
      zip

      # APPS CLI
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      ranger # file manager cli

      # DE
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
      ulauncher

      # APPS
      anki # mnemonic tool
      deluge # torrent client
      discord
      etcher # create booteable usbs
      filelight # view disk usage
      inkscape # photo editor cli/gui
      nomacs # image viewer/editor
      screenkey # show key pressed
      simplenote
      sublime3 # text editor
      zathura # PDF viewer
      zoom-us

      # Themes
      adwaita-qt
      capitaine-cursors
      hicolor-icon-theme
      papirus-icon-theme

      # Themes settings
      qt5.qtgraphicaleffects # required by gddm themes
      qt5ct
    ] ++ [
      localPkgs.eww # custom widgets daemon
      localPkgs.http-url-handler
      localPkgs.sddm-sugar-dark-greeter
      localPkgs.sddm-whitesur-greeter
      localPkgs.stremio
      localPkgs.zscroll # scroll text in shells
    ];
  };
}
