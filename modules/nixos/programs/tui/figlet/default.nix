{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.figlet;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in {
  options._custom.programs.figlet.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ figlet toilet ];

      home.sessionVariables.FIGLET_FONTDIR = "${hmConfig.xdg.dataHome}/figlet";

      # Adds "ANSI Shadow"
      xdg.dataFile."figlet".source = inputs.figlet-fonts;
    };
  };
}
