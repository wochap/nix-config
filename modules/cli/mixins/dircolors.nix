{ config, lib, inputs, ... }:

let
  cfg = config._custom.cli.dircolors;
  userName = config._userName;
in {
  options._custom.cli.dircolors = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
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

