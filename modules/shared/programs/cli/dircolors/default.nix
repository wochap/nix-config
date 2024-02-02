{ config, lib, inputs, ... }:

let cfg = config._custom.cli.dircolors;
in {
  options._custom.cli.dircolors.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.dircolors = {
        enable = true;
        enableBashIntegration = true;
        settings = lib.mkForce { };
        extraConfig =
          builtins.readFile "${inputs.catppuccin-dircolors}/.dircolors";
      };
    };
  };
}

