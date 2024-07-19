{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.hyprland;
  inherit (config._custom.globals) userName themeColors configDirectory;
  inherit (lib._custom) relativeSymlink;

  hyprland-final = inputs.hyprland.packages."${system}".hyprland;
  hyprland-xdp-final = pkgs.xdg-desktop-portal-hyprland;
  hyprland-focus-toggle = pkgs.writeScriptBin "hyprland-focus-toggle"
    (builtins.readFile ./scripts/hyprland-focus-toggle.sh);
  hyprland-scratch-toggle = pkgs.writeScriptBin "hyprland-scratch-toggle"
    (builtins.readFile ./scripts/hyprland-scratch-toggle.sh);
  stop-targets-str = ''
    pid=$!
    wait $pid
    systemctl --user stop graphical-session.target --quiet
    systemctl --user stop wayland-session.target --quiet
  '';
  hyprland-start = pkgs.writeScriptBin "hyprland-start" ''
    Hyprland "$@" > /home/${userName}/.cache/hyprland-logs 2> /home/${userName}/.cache/hyprland-stderr-logs &
    ${stop-targets-str}
  '';
  hyprland-start-with-dgpu-port =
    pkgs.writeScriptBin "hyprland-start-with-dgpu-port" ''
      # NOTE: This is specific for glegion host with nvidia
      # so I can use HDMI port connected directly to dGPU
      unset WLR_RENDERER; unset __EGL_VENDOR_LIBRARY_FILENAMES; WLR_DRM_DEVICES="$IGPU_CARD:$DGPU_CARD" Hyprland "$@" > /home/${userName}/.cache/hyprland-logs 2> /home/${userName}/.cache/hyprland-stderr-logs &
      ${stop-targets-str}
    '';
in {
  options._custom.desktop.hyprland = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ hyprland-start hyprland-start-with-dgpu-port ];

    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault "Hyprland";
    environment.etc = {
      "greetd/environments".text = lib.mkAfter ''
        Hyprland
        hyprland-start
        hyprland-start-with-dgpu-port
      '';
      "greetd/sessions/hyprland.dekstop".text = ''
        [Desktop Entry]
        Name=hyprland
        Comment=An intelligent dynamic tiling Wayland compositor
        Exec=hyprland-start
        Type=Application
      '';
      "greetd/sessions/hyprland-dgpu-port.dekstop".text = ''
        [Desktop Entry]
        Name=hyprland-dgpu-port
        Comment=An intelligent dynamic tiling Wayland compositor
        Exec=hyprland-start-with-dgpu-port
        Type=Application
      '';
    };

    programs.hyprland = {
      enable = true;
      package = hyprland-final;
      portalPackage = hyprland-xdp-final;
    };

    xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];

    systemd.user.services.xdg-desktop-portal-hyprland.serviceConfig.PassEnvironment =
      [ "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "QT_QPA_PLATFORMTHEME" "PATH" ];

    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;

    _custom.hm = {
      home.packages = [
        hyprland-focus-toggle
        hyprland-scratch-toggle
        inputs.pyprland.packages.${pkgs.system}.default
      ];

      xdg.configFile = {
        "hypr/colors.conf".text = lib.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList
            (key: value: "${"$"}${key}=${lib._custom.unwrapHex value}")
            themeColors);
        "hypr/keybindings.conf".source =
          relativeSymlink configDirectory ./dotfiles/keybindings.conf;
        "hypr/config.conf".source =
          relativeSymlink configDirectory ./dotfiles/config.conf;
        "hypr/pyprland.toml".source =
          relativeSymlink configDirectory ./dotfiles/pyprland.toml;

        "hypr/libinput-gestures.conf".text = ''
          gesture swipe left 3 hyprctl dispatch workspace e+1
          gesture swipe right 3 hyprctl dispatch workspace e-1
        '';
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprland-final;
        systemd.enable = false;
        extraConfig = ''
          source=~/.config/hypr/colors.conf
          source=~/.config/hypr/config.conf
          source=~/.config/hypr/keybindings.conf
        '';
      };
    };
  };
}
