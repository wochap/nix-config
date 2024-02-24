{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.openbox;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.openbox = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ openbox ];

    _custom.de.greetd.cmd = lib.mkIf cfg.isDefault "startx";

    _custom.hm = lib.mkMerge [
      {
        xdg.configFile."openbox/environment".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/environment;
        xdg.configFile."openbox/rc.xml".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/rc.xml;
        xdg.configFile."openbox/menu.xml".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/menu.xml;
        xdg.configFile."openbox/autostart".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/autostart;
      }

      (lib.mkIf cfg.isDefault {
        #
      })
    ];
  };
}

