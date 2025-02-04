{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.qt;
in {
  options._custom.desktop.qt = {
    enable = lib.mkEnableOption "setup qt theme and apps";
    enableTheme = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     # source: https://github.com/spikespaz/dotfiles/blob/352ce1a9b728f097bc3062fce95e07d11512a8b9/overlays/patches.nix#L38
    #     qt6Packages = prev.qt6Packages // {
    #       qt6ct = prev.qt6Packages.qt6ct.overrideAttrs (self: super: {
    #         patches = super.patches or [ ] ++ [
    #           (pkgs.fetchpatch {
    #             url =
    #               "https://patch-diff.githubusercontent.com/raw/trialuser02/qt6ct/pull/43.diff";
    #             hash = "sha256-bCXTbnMia9XzHPVe0dQSwSL7ijElS00wdNkviSrgk1A=";
    #           })
    #           (pkgs.fetchpatch {
    #             url =
    #               "https://patch-diff.githubusercontent.com/raw/trialuser02/qt6ct/pull/44.diff";
    #             hash = "sha256-fafLjzPFaIBwMJuFUWISZepPypr6P3SHm6+vIuEdTIY=";
    #           })
    #         ];
    #         buildInputs = super.buildInputs or [ ] ++ (with pkgs.kdePackages; [
    #           qtdeclarative
    #           kconfig
    #           kcolorscheme
    #           kiconthemes
    #         ]);
    #         # Original inputs removed, switch to cmake.
    #         nativeBuildInputs = with pkgs;
    #           with pkgs.kdePackages; [
    #             cmake
    #             qttools
    #             wrapQtAppsHook
    #           ];
    #         cmakeFlags = [
    #           "-DPLUGINDIR=${
    #             placeholder "out"
    #           }/${pkgs.kdePackages.qtbase.qtPluginPrefix}"
    #         ];
    #       });
    #     };
    #   })
    # ];

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
