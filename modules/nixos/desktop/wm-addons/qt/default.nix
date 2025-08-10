{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.qt;
  inherit (config._custom) globals;
  inherit (config._custom.globals)
    userName themeColorsLight themeColorsDark preferDark iconTheme;
  hmConfig = config.home-manager.users.${userName};

  catppuccin-kde-final = pkgs.catppuccin-kde.override {
    flavour = [ themeColorsLight.flavour themeColorsDark.flavour ];
    accents = [ cfg.theme.accent ];
    winDecStyles = [ "modern" ];
  };
  catppuccin-kde-light-theme-path =
    "${catppuccin-kde-final}/share/color-schemes/Catppuccin${
      lib._custom.capitalize themeColorsLight.flavour
    }${lib._custom.capitalize cfg.theme.accent}.colors";
  catppuccin-kde-dark-theme-path =
    "${catppuccin-kde-final}/share/color-schemes/Catppuccin${
      lib._custom.capitalize themeColorsDark.flavour
    }${lib._custom.capitalize cfg.theme.accent}.colors";
in {
  options._custom.desktop.qt = {
    enable = lib.mkEnableOption "setup qt theme and apps";
    enableTheme = lib.mkEnableOption { };
    enableQt6ctKde = lib.mkEnableOption { };
    enableQt5Integration = lib.mkEnableOption { };
    theme = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Darkly";
      };
      accent = lib.mkOption {
        type = lib.types.str;
        default = "lavender";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        catppuccin-qt5ct = prev.catppuccin-qt5ct.overrideAttrs (oldAttrs: rec {
          version = "cb585307edebccf74b8ae8f66ea14f21e6666535";
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "qt5ct";
            rev = version;
            hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
          };
        });
      })
    ] ++ lib.optionals cfg.enableQt6ctKde [
      (final: prev: {
        # override qt6ct with qt6ct-kde to fix style in kde apps
        # https://aur.archlinux.org/packages/qt6ct-kde
        kdePackages = prev.kdePackages.overrideScope (kdeSelf: kdePrev: {
          qt6ct = kdePrev.qt6ct.overrideAttrs (oldAttrs: rec {
            version = "23a985f45cf793ce7ce05811411d2374b4f979c4";
            src = pkgs.fetchFromGitLab {
              domain = "opencode.net";
              owner = "trialuser";
              repo = "qt6ct";
              rev = version;
              sha256 = "sha256-AUl2Se+8fUIeiYutObiM31VLbfJv09tpzJr3/2kB54c=";
            };
          });
        });
        qt6Packages = prev.qt6Packages.overrideScope (qt6Self: qt6Prev: {
          qt6ct = qt6Prev.qt6ct.overrideAttrs (oldAttrs: rec {
            version = "23a985f45cf793ce7ce05811411d2374b4f979c4";
            src = pkgs.fetchFromGitLab {
              domain = "opencode.net";
              owner = "trialuser";
              repo = "qt6ct";
              rev = version;
              sha256 = "sha256-AUl2Se+8fUIeiYutObiM31VLbfJv09tpzJr3/2kB54c=";
            };
          });
        });
      })
    ];

    fonts.packages = with pkgs; [ noto-fonts source-sans-pro ];

    environment.systemPackages = with pkgs;
      [
        # custom themes
        darkly

        # qt deps
        # source: https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/desktop-managers/plasma6.nix
        kdePackages.kconfig
        kdePackages.qtwayland # Hack? To make everything run on Wayland
        kdePackages.qtsvg # Needed to render SVG icons
        kdePackages.libplasma # provides Kirigami platform theme
        kdePackages.plasma-integration # provides Qt platform theme
        kdePackages.kservice # query DE info, kbuildsycoca6
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

        # qt deps
        libsForQt5.kconfig
      ];

    qt = {
      enable = cfg.enableTheme;
      platformTheme = "qt5ct";
    };

    _custom.hm = {
      home = {
        sessionVariables = {
          # Fake running KDE
          # https://wiki.archlinux.org/title/qt#Configuration_of_Qt_5_applications_under_environments_other_than_KDE_Plasma
          # https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#The_KDE_Plasma_XDG_Desktop_Portal_is_not_being_used
          # DESKTOP_SESSION = "KDE";

          # Blurred icon rendering on Wayland with fractional scaling
          # source: https://github.com/Bali10050/darkly?tab=readme-ov-file
          QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";

          QT_STYLE_OVERRIDE = lib.mkIf cfg.enableQt6ctKde "qt6ct-style";
        };

        symlinks = {
          "${hmConfig.home.homeDirectory}/.config/kdeglobals" =
            "${hmConfig.home.homeDirectory}/.config/kdeglobals-${
              if preferDark then "dark" else "light"
            }";
        };
      };

      xdg.configFile = {
        "qt5ct/colors/catppuccin-${themeColorsLight.flavour}-${cfg.theme.accent}.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-${themeColorsLight.flavour}-${cfg.theme.accent}.conf";
        "qt5ct/colors/catppuccin-${themeColorsDark.flavour}-${cfg.theme.accent}.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-${themeColorsDark.flavour}-${cfg.theme.accent}.conf";
        "qt6ct/colors/catppuccin-${themeColorsLight.flavour}-${cfg.theme.accent}.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-${themeColorsLight.flavour}-${cfg.theme.accent}.conf";
        "qt6ct/colors/catppuccin-${themeColorsDark.flavour}-${cfg.theme.accent}.conf".source =
          "${inputs.catppuccin-qt5ct}/themes/catppuccin-${themeColorsDark.flavour}-${cfg.theme.accent}.conf";

        # Fix mime apps
        # source: https://discourse.nixos.org/t/dolphin-does-not-have-mime-associations/48985
        "menus/applications.menu".source =
          "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

        "kdeglobals-light".text = ''
          # HACK: force kde apps to use kde catppuccin
          ${lib.fileContents catppuccin-kde-light-theme-path}

          [Icons]
          # HACK: force kde apps to use icon theme
          Theme=${iconTheme.name}-light

          [UiSettings]
          ColorScheme=qt6ct
        '';
        "kdeglobals-dark".text = ''
          # HACK: force kde apps to use kde catppuccin
          ${lib.fileContents catppuccin-kde-dark-theme-path}

          [Icons]
          # HACK: force kde apps to use icon theme
          Theme=${iconTheme.name}-dark

          [UiSettings]
          ColorScheme=qt6ct
        '';
      };
    };
  };
}
