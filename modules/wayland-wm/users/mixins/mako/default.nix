{ config, pkgs, lib, ... }:

let
  inherit (config._custom) globals;
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/users/mixins/mako";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ mako libnotify dunst ];
      etc = {
        "assets/notification.flac" = {
          source = ./assets/notification.flac;
          mode = "0755";
        };
        "scripts/mako/mako-toggle-mode.sh" = {
          source = ./scripts/mako-toggle-mode.sh;
          mode = "0755";
        };
        "scripts/mako/mako-start.sh" = {
          source = ./scripts/mako-start.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "mako/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
      };

      systemd.user.services.mako = {
        Unit = {
          Description = "A lightweight Wayland notification daemon";
          Documentation = "https://github.com/emersion/mako";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [
            "XCURSOR_THEME=${globals.cursor.name}"
            "XCURSOR_SIZE=${toString globals.cursor.size}"
          ];
          ExecStart = "${pkgs.mako}/bin/mako";
          ExecReload = "${pkgs.mako}/bin/makoctl reload";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
