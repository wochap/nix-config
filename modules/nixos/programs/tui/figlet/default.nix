{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.figlet;
in {
  options._custom.programs.figlet.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ figlet toilet ];

      xdg.dataFile."figlet".source = inputs.figlet-fonts;
    };
  };
}
