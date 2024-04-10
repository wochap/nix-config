{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.foot;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.foot.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ foot ];

      xdg.configFile."foot/foot.ini".text = ''
        ${builtins.readFile ./dotfiles/foot.ini}
        ${builtins.readFile
        "${inputs.catppuccin-foot}/catppuccin-${themeColors.flavor}.ini"}
      '';
    };
  };
}
