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
      glib # gio
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
      docker-compose
      gotop # monitor system
      htop # monitor system
      neofetch # print computer info
      nvtop # monitor system nvidia
      radeontop # monitor system amd
      ranger # file manager cli
      scrot # screen capture

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
      # gnome3.bijiben
      # gnome3.gnome-disk-utility
      anki # mnemonic tool
      deluge # torrent client
      discord
      etcher # create booteable usbs
      filelight # view disk usage
      gnome3.cheese # test webcam
      gnome3.eog # image viewer
      gnome3.evolution # email/calendar client
      gnome3.file-roller # archive manager
      gnome3.geary # email client
      gnome3.gnome-calculator
      gnome3.gnome-calendar
      gnome3.gnome-clocks
      gnome3.gnome-control-center # add google account for gnome apps
      gnome3.gnome-font-viewer
      gnome3.gnome-sound-recorder # test microphone
      gnome3.gnome-system-monitor
      gnome3.gnome-todo
      gnome3.pomodoro
      gtimelog
      inkscape # photo editor cli/gui
      nomacs # image viewer/editor
      screenkey # show key pressed
      simplenote
      sublime3 # text editor
      xfce.exo
      (xfce.thunar.override {
        thunarPlugins = [
          xfce.thunar-archive-plugin
        ];
      })
      xfce.thunar # file manager
      xfce.thunar-volman # auto mont devices
      xfce.xfconf # where thunar settings are saved
      zathura # PDF viewer
      zoom-us

      # Themes
      adwaita-qt
      capitaine-cursors
      gnome3.adwaita-icon-theme
      hicolor-icon-theme
      papirus-icon-theme

      # Themes settings
      gnome3.gsettings-desktop-schemas
      gtk-engine-murrine
      gtk_engines
      lxappearance
      qt5.qtgraphicaleffects # required by gddm themes
      qt5ct
    ] ++ [
      localPkgs.eww # custom widgets daemon
      localPkgs.http-url-handler
      localPkgs.sddm-sugar-dark-greeter
      localPkgs.sddm-whitesur-greeter
      localPkgs.stremio
      localPkgs.whitesur-dark-icons
      localPkgs.zscroll # scroll text in shells
    ];
  };
}
