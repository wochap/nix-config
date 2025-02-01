{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom.globals) themeColors configDirectory;
  inherit (lib._custom) relativeSymlink;

  hyprland-final = inputs.hyprland.packages."${system}".hyprland;
  hyprland-xdp-final =
    inputs.hyprland.packages."${system}".xdg-desktop-portal-hyprland;
  hyprland-focus-toggle = pkgs.writeScriptBin "hyprland-focus-toggle"
    (builtins.readFile ./scripts/hyprland-focus-toggle.sh);
  hyprland-scratch-toggle = pkgs.writeScriptBin "hyprland-scratch-toggle"
    (builtins.readFile ./scripts/hyprland-scratch-toggle.sh);
  greetd-default-cmd =
    "uwsm start -S -F -N hyprland -D hyprland -- /run/current-system/sw/bin/Hyprland";
in {
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # TODO: use hyprland.dekstop as default
    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault greetd-default-cmd;
    environment.etc = {
      "greetd/environments".text = lib.mkAfter ''
        Hyprland
      '';
      "greetd/sessions/hyprland-uwsm.dekstop".text = ''
        [Desktop Entry]
        Name=hyprland (UWSM)
        Comment=Hyprland compositor
        Exec=${greetd-default-cmd}
        Type=Application
      '';
      "greetd/sessions/hyprland-dgpu-uwsm.dekstop".text = ''
        [Desktop Entry]
        Name=hyprland-dgpu (UWSM)
        Comment=Hyprland compositor
        Exec=uwsm start -S -F -N hyprland-dgpu -D hyprland -- /run/current-system/sw/bin/Hyprland
        Type=Application
      '';
    };

    programs.hyprland = {
      enable = true;
      package = hyprland-final;
      portalPackage = hyprland-xdp-final;
      withUWSM = false;
      systemd.setPath.enable = false;
    };

    xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];

    _custom.hm = {
      home.packages = [
        hyprland-focus-toggle
        hyprland-scratch-toggle
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
        "hypr/colors.conf".text = lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList
            (key: value: "${"$"}${key}=${lib._custom.unwrapHex value}")
            themeColors);
        "hypr/keybindings.conf".source =
          relativeSymlink configDirectory ./dotfiles/keybindings.conf;
        "hypr/config.conf".source =
          relativeSymlink configDirectory ./dotfiles/config.conf;
        "hypr/autostart.conf".source =
          relativeSymlink configDirectory ./dotfiles/autostart.conf;
        "hypr/pyprland.toml".source =
          relativeSymlink configDirectory ./dotfiles/pyprland.toml;

        "hypr/libinput-gestures.conf".text = ''
          gesture swipe left 3 hyprctl dispatch workspace e+1
          gesture swipe right 3 hyprctl dispatch workspace e-1
        '';

        "uwsm/env-hyprland".text = common-env-hyprland;
        "uwsm/env-hyprland-dgpu".text = ''
          ${common-env-hyprland}

          # env variables for starting hyprland with discrete gpu
          # NOTE: This is specific to glegion host with nvidia
          # to enable using the HDMI port connected directly to the dGPU
          export WLR_RENDERER=
          export __EGL_VENDOR_LIBRARY_FILENAMES=
          export AQ_DRM_DEVICES=$IGPU_CARD:$DGPU_CARD
        '';
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprland-final;
        systemd.enable = false;
        extraConfig = ''
          source=~/.config/hypr/colors.conf
          source=~/.config/hypr/config.conf
          source=~/.config/hypr/autostart.conf
          source=~/.config/hypr/keybindings.conf
        '';
      };
    };
  };
}
