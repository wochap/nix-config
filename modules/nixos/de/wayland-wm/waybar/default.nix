{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  inherit (config._custom.globals) configDirectory;
  inherit (lib._custom) relativeSymlink;
  waybar = pkgs.waybar;
in {
  imports = [ ./waybar-config.nix ];

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ waybar pkgs.libevdev ];
      etc = {
        "scripts/waybar/waybar-toggle.sh" = {
          source = ./scripts/waybar-toggle.sh;
          mode = "0755";
        };
      };
    };

    _custom.hm = {
      imports = [ ./options.nix ];

      xdg.configFile = {
        "waybar/style.css".source =
          relativeSymlink configDirectory ./dotfiles/style.css;
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
          ExecStart = "${waybar}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
