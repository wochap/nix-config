{ config, pkgs, lib, libAttr, ... }:

let
  cfg = config._custom.waylandWm;
  theme = config._theme;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory =
    "${configDirectory}/modules/wayland-wm/users/mixins/waybar";
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ waybar libevdev ];
      etc = {
        "scripts/waybar/waybar-toggle.sh" = {
          source = ./scripts/waybar-toggle.sh;
          mode = "0755";
        };
        "scripts/waybar/waybar-start.sh" = {
          source = ./scripts/waybar-start.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "waybar/config".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
        "waybar/style.css".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
        "waybar/colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") theme)}
        '';
      };

      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
