{ config, lib, pkgs, ... }:

let
  cfg = config._custom.desktop.tofi;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  tofi-launcher = pkgs.writeScriptBin "tofi-launcher"
    (builtins.readFile ./scripts/tofi-launcher.sh);
  tofi-powermenu = pkgs.writeScriptBin "tofi-powermenu"
    (builtins.readFile ./scripts/tofi-powermenu.sh);
  tofi-emoji = pkgs.writeScriptBin "tofi-emoji"
    (builtins.readFile ./scripts/tofi-emoji.sh);
  tofi-calc =
    pkgs.writeScriptBin "tofi-calc" (builtins.readFile ./scripts/tofi-calc.sh);
  mkThemeTofi = themeColors: ''
    # Fonts
    font = "Iosevka NF"

    # Text theming
    text-color = ${themeColors.text}

    prompt-color = ${themeColors.textDimmed}

    selection-color = ${themeColors.backgroundOverlay}
    selection-background = ${themeColors.green}

    selection-match-color = ${themeColors.backgroundOverlay}

    # Window theming
    background-color = ${themeColors.backgroundOverlay}
  '';
  catppuccin-tofi-light-theme = mkThemeTofi themeColorsLight;
  catppuccin-tofi-dark-theme = mkThemeTofi themeColorsDark;
in {
  options._custom.desktop.tofi.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [
          tofi
          tofi-launcher
          tofi-powermenu
          tofi-emoji
          tofi-calc
        ];
      };

      xdg.configFile = {
        "tofi/multi-line".source = ./dotfiles/multi-line;
        "tofi/one-line".source = ./dotfiles/one-line;
        "tofi/one-line-theme" = {
          text = if preferDark then
            catppuccin-tofi-dark-theme
          else
            catppuccin-tofi-light-theme;
          force = true;
        };
        "tofi/one-line-theme-light".text = catppuccin-tofi-light-theme;
        "tofi/one-line-theme-dark".text = catppuccin-tofi-dark-theme;
        ".local/share/tofi/emojis.txt".source = ./dotfiles/emojis.txt;
      };
    };
  };
}
