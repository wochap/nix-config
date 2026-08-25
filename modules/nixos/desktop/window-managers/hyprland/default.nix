{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom) globals;
  inherit (globals)
    themeColorsLight
    themeColorsDark
    preferDark
    configDirectory
    ;
  inherit (lib._custom) relativeSymlink;

  mkThemeLua =
    colors:
    "return {\n"
    + lib.concatStringsSep ",\n" (
      lib.attrsets.mapAttrsToList (key: value: "  ${key} = \"#${lib._custom.unwrapHex value}\"") colors
    )
    + ",\n}\n";
  catppuccin-hyprland-light-theme = mkThemeLua themeColorsLight;
  catppuccin-hyprland-dark-theme = mkThemeLua themeColorsDark;
  hyprland-guiutils =
    inputs.hyprland-guiutils.packages.${pkgs.stdenv.hostPlatform.system}.hyprland-guiutils;
  hyprplugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
  hyprland-final = inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland;
  hyprland-xdph-final =
    inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}".xdg-desktop-portal-hyprland;
  hyprcursor-conf = ''
    -- hyprcursor config
    hl.env("HYPRCURSOR_THEME", "${config._custom.desktop.cursor.name}")
    hl.env("HYPRCURSOR_SIZE", "${toString config._custom.desktop.cursor.size}")
  '';
in
{
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
    uwsmSessionVariables = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."greetd/environments".text = lib.mkAfter ''
      Hyprland
      start-hyprland
    '';

    _custom.desktop.uwsm.waylandCompositors = {
      hyprland = {
        prettyName = "hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/start-hyprland";
        xdgCurrentDesktop = "Hyprland";
      };
    };

    _custom.desktop.ydotool.enableSystemd = lib.mkIf cfg.isDefault true;

    services.displayManager.defaultSession = lib.mkIf cfg.isDefault "hyprland-uwsm";

    programs.hyprland = {
      enable = true;
      package = hyprland-final;
      portalPackage = hyprland-xdph-final;
      # HACK: prevent adding vanilla Hyprland into `services.displayManager.sessionPackages`
      withUWSM = true;
      systemd.setPath.enable = false;
    };

    xdg.portal.config = {
      common."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      Hyprland."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };

    # NOTE: not sure why xdg-desktop-portal picks
    # "hyprland" and not "Hyprland"
    # maybe because of uwsm?
    xdg.portal.config.Hyprland.default = [
      "gtk"
      "hyprland"
    ];
    xdg.portal.config.hyprland.default = [
      "gtk"
      "hyprland"
    ];

    _custom.hm = {
      home.packages = with pkgs; [
        hyprland-qt-support
        hyprland-guiutils
        hyprpaper
        hyprshade # NOTE: v5 is buggy
        hyprshutdown
      ];

      xdg.configFile = {
        "scripts/hyprland".source = lib._custom.relativeSymlink configDirectory ./scripts/automation;

        "remmina/hypr-glegion.remmina".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/hypr-glegion.remmina;

        "hypr/xdph.conf".source = lib._custom.relativeSymlink configDirectory ./dotfiles/xdph.conf;

        "hypr/colors.lua" = {
          text = if preferDark then catppuccin-hyprland-dark-theme else catppuccin-hyprland-light-theme;
          force = true;
        };
        "hypr/colors-light.lua".text = catppuccin-hyprland-light-theme;
        "hypr/colors-dark.lua".text = catppuccin-hyprland-dark-theme;
        "hypr/hyprland/binds.lua".source = relativeSymlink configDirectory ./dotfiles/hyprland/binds.lua;
        "hypr/hyprland/keywords.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/keywords.lua;
        "hypr/hyprland/rules.lua".source = relativeSymlink configDirectory ./dotfiles/hyprland/rules.lua;
        "hypr/hyprland/variables.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/variables.lua;
        "hypr/hyprland/constants.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/constants.lua;
        "hypr/hyprland/lib/theme.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/theme.lua;
        "hypr/hyprland/lib/active_border.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/active_border.lua;
        "hypr/hyprland/lib/harpoon.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/harpoon.lua;
        "hypr/hyprland/lib/harpoon_scratchpad.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/harpoon_scratchpad.lua;
        "hypr/hyprland/lib/previous_ws.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/previous_ws.lua;
        "hypr/hyprland/lib/scratchpad.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/scratchpad.lua;
        "hypr/hyprland/lib/scratchpad_common.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/scratchpad_common.lua;
        "hypr/hyprland/lib/ws_offset.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/ws_offset.lua;
        "hypr/hyprland/lib/zoom.lua".source =
          relativeSymlink configDirectory ./dotfiles/hyprland/lib/zoom.lua;
        "hypr/kiosk.lua".text = ''
          local constants = require("hyprland.constants")
          constants.is_kiosk = true

          require("hyprland.variables")
          require("hyprland.keywords")
          require("hyprland.rules")
          require("hyprland.binds")

          ${hyprcursor-conf}
        '';

        "hypr/shaders".source = relativeSymlink configDirectory ./dotfiles/shaders;

        "uwsm/env-hyprland".text = ''
          # toolkit-specific scale
          export GDK_SCALE=2;
          # export QT_AUTO_SCREEN_SCALE_FACTOR=0;
          # export QT_ENABLE_HIGHDPI_SCALING=0;
          # export QT_SCALE_FACTOR=2;
          # export QT_FONT_DPI=96;

          ${lib.concatStringsSep "\n" (
            lib.attrsets.mapAttrsToList (key: value: "export ${key}=${value};") cfg.uwsmSessionVariables
          )}
        '';
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprland-final;
        portalPackage = null;
        systemd.enable = false;
        configType = "lua";
        plugins = with hyprplugins; [
          # better preview all workspaces
          # inputs.hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace

          # preview all workspaces
          # hyprexpo

          # touch screen support gestures
          # inputs.hyprgrass.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        extraConfig = ''
          require("hyprland.variables")
          require("hyprland.keywords")
          require("hyprland.rules")
          require("hyprland.binds")

          ${hyprcursor-conf}
        '';
      };
    };
  };
}
