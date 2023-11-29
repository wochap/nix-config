{ config, pkgs, lib, _customLib, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);
  inherit (pkgs.unstable) waybar;
in {
  imports = [ ./waybar-config.nix ];

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
          src = prev.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "a90e275d5e26226c9e69abbb6f9be4d7391ba3c1";
            hash = "sha256-AKjdQH+jey1A235xQXVtogeqLUaB/SBfraGJw/tvwz8=";
          };
        });
      })
    ];

    environment = {
      systemPackages = [ waybar pkgs.libevdev ];
      etc = {
        "scripts/waybar/waybar-toggle.sh" = {
          source = ./scripts/waybar-toggle.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      imports = [ ./options.nix ];

      xdg.configFile = {
        "waybar/style.css".source = relativeSymlink ./dotfiles/style.css;
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
