{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.qt;
in {
  options._custom.desktop.qt = {
    enable = lib.mkEnableOption "setup qt theme and apps";
    enableTheme = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [ source-sans-pro ];

    environment.systemPackages = with pkgs; [
      kdePackages.qtwayland # qt6
      libsForQt5.qt5.qtwayland

      # kvantum (not required but...)
      libsForQt5.qtstyleplugins
      libsForQt5.qtstyleplugin-kvantum

      # fix kirigami apps look
      # for example in filelight, without it the app looks weird
      # https://github.com/NixOS/nixpkgs/pull/202990#issuecomment-1328068486
      kdePackages.qqc2-desktop-style # qt6
      libsForQt5.qqc2-desktop-style

      # themes qt5
      lightly-boehs
      libsForQt5.breeze-icons
      libsForQt5.breeze-qt5
      catppuccin-qt5ct
      (catppuccin-kvantum.override {
        accent = "mauve";
        variant = "mocha";
      })

      # themes qt6
      kdePackages.breeze-icons
      kdePackages.breeze
    ];

    qt = {
      enable = cfg.enableTheme;
      platformTheme = "qt5ct";
    };

    _custom.hm = {
      home.sessionVariables = {
        # Fake running KDE
        # https://wiki.archlinux.org/title/qt#Configuration_of_Qt_5_applications_under_environments_other_than_KDE_Plasma
        # https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#The_KDE_Plasma_XDG_Desktop_Portal_is_not_being_used
        DESKTOP_SESSION = "KDE";

        # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      xdg.configFile = {
        "qt5ct/colors/Catppuccin-Mocha-Mauve.conf".source =
          ./dotfiles/Catppuccin-Mocha-Mauve.conf;
        "qt6ct/colors/Catppuccin-Mocha-Mauve.conf".source =
          ./dotfiles/Catppuccin-Mocha-Mauve.conf;
      };

      qt = {
        enable = cfg.enableTheme;
        platformTheme.name = "qtct";
      };
    };
  };
}
