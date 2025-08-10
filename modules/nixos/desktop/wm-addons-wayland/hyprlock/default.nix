{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.hyprlock;
  inherit (config._custom.globals) configDirectory themeColors;
  inherit (lib._custom) relativeSymlink unwrapHex;
  hyprlock-start = pkgs.writeScriptBin "hyprlock-start"
    (builtins.readFile ./scripts/hyprlock-start.sh);
in {
  options._custom.desktop.hyprlock.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: necessary for hyprlock to unlock
    security.pam.services.hyprlock.text = ''
      auth include login
    '';

    _custom.hm = {
      home.packages = with pkgs; [
        inputs.hyprlock.packages.${system}.hyprlock
        hyprlock-start
      ];

      xdg.configFile = {
        "hypr/hyprlock.conf".source =
          relativeSymlink configDirectory ./dotfiles/hyprlock.conf;
        "hypr/catppuccin-theme.conf".source =
          "${inputs.catppuccin-hyprland}/themes/${themeColors.flavour}.conf";
        "hypr/theme-colors.conf".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "\$${key} = rgb(${unwrapHex value})")
            (builtins.removeAttrs themeColors [ "flavour" ]))}
        '';
      };
    };
  };
}

