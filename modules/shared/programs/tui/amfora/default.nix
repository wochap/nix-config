{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.amfora;
in {
  options._custom.programs.amfora.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ amfora ];

      xdg.configFile."amfora/config.toml".text = ''
        ${builtins.readFile ./dotfiles/config.toml}
        ${builtins.readFile "${inputs.catppuccin-amfora}/themes/mocha.toml"}
      '';
    };
  };
}
