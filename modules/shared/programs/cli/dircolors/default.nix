{ config, lib, inputs, ... }:

let cfg = config._custom.programs.dircolors;
in {
  options._custom.programs.dircolors.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.dircolors = {
        enable = true;
        enableZshIntegration = config._custom.programs.zsh.enable;
        settings = lib.mkForce { };
        # TODO: support other flavors
        extraConfig =
          builtins.readFile "${inputs.catppuccin-dircolors}/.dircolors";
      };
    };
  };
}

