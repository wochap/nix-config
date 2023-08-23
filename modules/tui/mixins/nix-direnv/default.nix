{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.nixDirenv;
  userName = config._userName;
in {
  options._custom.tui.nixDirenv = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ direnv nix-direnv ];
    # nix options for derivations to persist garbage collection
    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };
    environment.pathsToLink = [ "/share/nix-direnv" ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "direnv/direnvrc".source = ./dotfiles/direnv;
      };
    };
  };
}
