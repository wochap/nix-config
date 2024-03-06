{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.amfora;
in {
  options._custom.programs.amfora.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ amfora ];

    _custom.hm = {
      xdg.configFile."amfora/config.toml".text = ''
        ${builtins.readFile ./dotfiles/config.toml}
        ${builtins.readFile "${inputs.catppuccin-amfora}/themes/mocha.toml"}
      '';
    };
  };
}
