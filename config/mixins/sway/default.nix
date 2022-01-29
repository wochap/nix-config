{ config, pkgs, lib, ... }:

let
  startsway = pkgs.writeTextFile {
    name = "startsway";
    destination = "/bin/startsway";
    executable = true;
    text = builtins.readFile ./scripts/startsway.sh;
  };
in {
  config = {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = [ ]; # block rxvt

      # TODO: if nvidia
      # extraOptions = [
      #   "--unsupported-gpu"
      # ];
    };

    environment = {
      systemPackages = with pkgs; [ startsway ];

      etc = {
        "sway/config".source = ./dotfiles/config.sh;
        "sway/borders".source = ./assets/borders;

        "scripts/sway-lock.sh" = {
          source = ./scripts/sway-lock.sh;
          mode = "0755";
        };
      };
    };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.sway = {
      description = "Sway - Wayland window manager";
      documentation = [ "man:sway(5)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
      # We explicitly unset PATH here, as we want it to be set by
      # systemctl --user import-environment in startsway
      environment.PATH = lib.mkForce null;
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --unsupported-gpu --debug
        '';
        Restart = "on-failure";
        RestartSec = 3;
        TimeoutStopSec = 10;
      };
    };
  };
}
