{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.qt;
  inherit (config._custom.globals) themeColors;

  catppuccin-kde-final = pkgs.catppuccin-kde.override {
    flavour = [ "latte" "mocha" ];
    accents = [ "mauve" ];
    winDecStyles = [ "modern" ];
  };
in {
  options._custom.desktop.qt = {
    enable = lib.mkEnableOption "setup qt theme and apps";
    enableTheme = lib.mkEnableOption { };
    enableQt5Integration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [ noto-fonts source-sans-pro ];

    environment.systemPackages = with pkgs;
      [
        # custom themes
        darkly

        # qt deps
        # source: https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/desktop-managers/plasma6.nix
        kdePackages.qtwayland # Hack? To make everything run on Wayland
        kdePackages.qtsvg # Needed to render SVG icons
        kdePackages.libplasma # provides Kirigami platform theme
        kdePackages.plasma-integration # provides Qt platform theme
        # kdePackages.plasma-workspace

        # kde/qt themes
        kdePackages.breeze
        kdePackages.breeze-icons
        kdePackages.breeze-gtk
        kdePackages.ocean-sound-theme
        kdePackages.qqc2-breeze-style
        kdePackages.qqc2-desktop-style
        catppuccin-kde-final
        hicolor-icon-theme # fallback icons
      ] ++ lib.optionals cfg.enableQt5Integration [
        # custom themes
        darkly-qt5
        # catppuccin-qt5ct

        # kde/qt themes
        kdePackages.breeze.qt5
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

        # Blurred icon rendering on Wayland with fractional scaling
        # source: https://github.com/Bali10050/darkly?tab=readme-ov-file
        QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
      };

      xdg.configFile = {
        "qt5ct/colors/Catppuccin-Mocha-Mauve.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-mocha-mauve.conf";
        "qt6ct/colors/Catppuccin-Mocha-Mauve.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-mocha-mauve.conf";

        # Fix mime apps
        # source: https://discourse.nixos.org/t/dolphin-does-not-have-mime-associations/48985
        "menus/applications.menu".source =
          "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

        # HACK: force theme on QT6 KDE apps
        "kdeglobals".text = ''
          ${builtins.readFile
          "${catppuccin-kde-final}/share/color-schemes/CatppuccinMochaMauve.colors"}

          [UiSettings]
          ColorScheme=qt6ct
        '';
      };
    };
  };
}
