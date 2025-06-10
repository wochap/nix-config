{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom) globals;
  inherit (globals) themeColors configDirectory;
  inherit (lib._custom) relativeSymlink;

  hyprplugins = inputs.hyprland-plugins.packages.${pkgs.system};
  hyprland-final = inputs.hyprland.packages."${system}".hyprland;
  hyprland-xdp-final =
    inputs.hyprland.packages."${system}".xdg-desktop-portal-hyprland;
  hyprland-scratchpad = pkgs.writeScriptBin "hyprland-scratchpad"
    (builtins.readFile ./scripts/hyprland-scratchpad.sh);
  hyprland-monocle = pkgs.writeScriptBin "hyprland-monocle"
    (builtins.readFile ./scripts/hyprland-monocle.sh);
  hyprland-socket = pkgs.writeScriptBin "hyprland-socket"
    (builtins.readFile ./scripts/hyprland-socket.sh);
in {
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."greetd/environments".text = lib.mkAfter ''
      Hyprland
    '';

    _custom.desktop.uwsm.waylandCompositors = {
      hyprland = {
        prettyName = "hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
        xdgCurrentDesktop = "Hyprland";
      };
      hyprland-dgpu = {
        prettyName = "hyprland-dgpu";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
        xdgCurrentDesktop = "Hyprland";
      };
    };

    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.desktop.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

    programs.hyprland = {
      enable = true;
      package = hyprland-final;
      portalPackage = hyprland-xdp-final;
      withUWSM = false;
      systemd.setPath.enable = false;
    };

    xdg.portal.config.Hyprland.default = [ "hyprland" "gtk" ];

    _custom.hm = {
      home.packages = [
        hyprland-scratchpad
        hyprland-monocle
        hyprland-socket
        inputs.pyprland.packages.${pkgs.system}.default
      ];

      xdg.configFile = let
        common-env-hyprland = ''
          # toolkit-specific scale
          export GDK_SCALE=2
          # export QT_AUTO_SCREEN_SCALE_FACTOR=0
          # export QT_ENABLE_HIGHDPI_SCALING=0
          # export QT_SCALE_FACTOR=2
          # export QT_FONT_DPI=96
        '';
      in {
        "scripts/hyprland" = {
          recursive = true;
          source = ./scripts/automation;
        };

        "remmina/hypr-glegion.remmina".source =
          lib._custom.relativeSymlink configDirectory
          ./dotfiles/hypr-glegion.remmina;

        "hypr/xdph.conf".text = ''
          screencopy {
            max_fps = 60
            allow_token_by_default = true
          }
        '';

        "hypr/colors.conf".text = lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList
            (key: value: "${"$"}${key}=${lib._custom.unwrapHex value}")
            themeColors);
        "hypr/keybindings.conf".source =
          relativeSymlink configDirectory ./dotfiles/keybindings.conf;
        "hypr/keybindings-kiosk.conf".source =
          relativeSymlink configDirectory ./dotfiles/keybindings-kiosk.conf;
        "hypr/config.conf".source =
          relativeSymlink configDirectory ./dotfiles/config.conf;
        "hypr/autostart.conf".source =
          relativeSymlink configDirectory ./dotfiles/autostart.conf;
        "hypr/pyprland.toml".source =
          relativeSymlink configDirectory ./dotfiles/pyprland.toml;
        "hypr/kiosk.conf".text = ''
          source=~/.config/hypr/colors.conf
          source=~/.config/hypr/config.conf
          source=~/.config/hypr/keybindings-kiosk.conf

          # hyprcursor config
          env = HYPRCURSOR_THEME,${globals.cursor.name}
          env = HYPRCURSOR_SIZE,${toString globals.cursor.size}
        '';

        "hypr/libinput-gestures.conf".source =
          ./dotfiles/libinput-gestures.conf;

        "uwsm/env-hyprland".text = ''
          ${common-env-hyprland}

          export AQ_DRM_DEVICES=$IGPU_CARD:$DGPU_CARD
        '';

        "uwsm/env-hyprland-dgpu".text = ''
          ${common-env-hyprland}

          # env variables for starting hyprland with discrete gpu
          # NOTE: This is specific to glegion host with nvidia
          # to enable using the HDMI port connected directly to the dGPU
          export __EGL_VENDOR_LIBRARY_FILENAMES=
          export AQ_DRM_DEVICES=$IGPU_CARD:$DGPU_CARD
        '';
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprland-final;
        portalPackage = null;
        systemd.enable = false;
        plugins = with hyprplugins;
          [
            hyprexpo
            # inputs.hyprgrass.packages.${pkgs.system}.default
          ];
        extraConfig = ''
          source=~/.config/hypr/colors.conf
          source=~/.config/hypr/config.conf
          source=~/.config/hypr/autostart.conf
          source=~/.config/hypr/keybindings.conf

          # hyprcursor config
          env = HYPRCURSOR_THEME,${globals.cursor.name}
          env = HYPRCURSOR_SIZE,${toString globals.cursor.size}
        '';
      };
    };
  };
}
