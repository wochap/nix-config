{ config, lib, pkgs, ... }:

let
  cfg = config._custom.de.tint2;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.tint2.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ tint2 ];

      xdg.configFile."tint2/tint2rc".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/tint2rc;

      systemd.user.services.waybar = {
        Unit = {
          Description = "A lightweight panel/taskbar for Linux and BSD";
          Documentation = "https://gitlab.com/o9000/tint2";
          PartOf = [ "xorg-session.target" ];
          After = [ "xorg-session.target" ];
        };

        Service = {
          PassEnvironment = "PATH";
          ExecStart = "${pkgs.tint2}/bin/tint2";
        };

        Install.WantedBy = [ "xorg-session.target" ];
      };
    };
  };
}

