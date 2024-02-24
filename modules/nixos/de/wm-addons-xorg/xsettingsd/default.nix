{ config, lib, pkgs, ... }:

let
  cfg = config._custom.de.xsettingsd;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.xsettingsd.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ xsettingsd ];

      xdg.configFile = {
        # Gtk settings
        # https://github.com/GNOME/gnome-settings-daemon/blob/master/plugins/xsettings/gsd-xsettings-manager.c
        "xsettingsd/xsettingsd.conf".source =
          lib._custom.relativeSymlink configDirectory
          ./dotfiles/xsettingsd.conf;
      };

      systemd.user.services.xsettingsd = {
        Unit = {
          Description = "xsettingsd";
          PartOf = [ "xorg-session.target" ];
          After = [ "xorg-session.target" ];
        };

        Service = {
          PassEnvironment = "PATH";
          ExecStart =
            "${cfg.package}/bin/xsettingsd -c $HOME/.config/xsettingsd/xsettingsd.conf";
          Restart = "on-abort";
        };

        Install.WantedBy = [ "xorg-session.target" ];
      };
    };
  };
}
