{ config, lib, inputs, ... }:

let cfg = config._custom.programs.dircolors;
in {
  options._custom.programs.dircolors.enable = lib.mkEnableOption { };

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

