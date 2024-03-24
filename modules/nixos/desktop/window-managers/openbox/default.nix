{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.openbox;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.desktop.openbox = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ openbox obconf ];

    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault "startx";

    services.xserver.windowManager.session = [{
      name = "openbox";
      start = "${pkgs.openbox}/bin/openbox-session";
    }];

    _custom.hm = lib.mkMerge [
      {
        xdg.configFile."openbox".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles;
      }

      (lib.mkIf cfg.isDefault {
        #
      })
    ];
  };
}

