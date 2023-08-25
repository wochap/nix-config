{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/mixins/waybar";
in {
  imports = [ ./waybar-config.nix ];

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
      imports = [ ./options.nix ];

      xdg.configFile = {
        # "waybar/config".source =
        #   mkOutOfStoreSymlink "${currentDirectory}/dotfiles/config";
        "waybar/style.css".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/style.css";
        "waybar/colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") themeColors)}
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
          PassEnvironment = "PATH";
          ExecStart = "${pkgs.unstable.waybar}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
