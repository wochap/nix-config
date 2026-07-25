{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.hyprlock;
  inherit (config._custom.globals)
    configDirectory
    themeColorsLight
    themeColorsDark
    preferDark
    ;
  inherit (lib._custom) relativeSymlink;
  hyprlock-start = pkgs.writeScriptBin "hyprlock-start" (
    builtins.readFile ./scripts/hyprlock-start.sh
  );

  mkThemeHyprlang =
    colors:
    lib.concatStringsSep "\n" (
      lib.attrsets.mapAttrsToList (key: value: "${"$"}${key}=${lib._custom.unwrapHex value}") colors
    );
  catppuccin-hyprlang-light-theme = mkThemeHyprlang themeColorsLight;
  catppuccin-hyprlang-dark-theme = mkThemeHyprlang themeColorsDark;
in
{
  options._custom.desktop.hyprlock.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: necessary for hyprlock to unlock
    security.pam.services.hyprlock.text = ''
      auth include login
    '';

    _custom.hm = {
      home.packages = with pkgs; [
        inputs.hyprlock.packages.${stdenv.hostPlatform.system}.hyprlock
        hyprlock-start
      ];

      # NOTE: we use hyprland module colors.conf
      xdg.configFile = {
        "hypr/hyprlock.conf".source = relativeSymlink configDirectory ./dotfiles/hyprlock.conf;
        "hypr/colors.conf" = {
          text = if preferDark then catppuccin-hyprlang-dark-theme else catppuccin-hyprlang-light-theme;
          force = true;
        };
      };
    };
  };
}
