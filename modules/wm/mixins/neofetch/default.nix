{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.neofetch;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (pkgs._custom.runtimePath config._custom.globals.configDirectory path);
in {
  options._custom.wm.neofetch = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch

      # Image preview on terminal
      w3m
      imagemagick
    ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "neofetch/config.conf".source = relativeSymlink ./dotfiles/config.conf;
      };
    };
  };
}
