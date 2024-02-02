{ config, lib, pkgs, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;

  tofi-launcher =
    pkgs.writeScriptBin "tofi-launcher" ./scripts/tofi-launcher.sh;
  tofi-powermenu = pkgs.writeScriptBin "tofi-powermenu"
    (builtins.readFile ./scripts/tofi-powermenu.sh);
  tofi-emoji = pkgs.writeScriptBin "tofi-emoji"
    (builtins.readFile ./scripts/tofi-emoji.sh);
  tofi-calc =
    pkgs.writeScriptBin "tofi-calc" (builtins.readFile ./scripts/tofi-calc.sh);
in {
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
        "tofi/one-line".source = pkgs.substituteAll {
          src = ./dotfiles/one-line;
          inherit (themeColors) foreground primary background red;
        };
      };
    };
  };
}
