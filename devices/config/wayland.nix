{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    programs.waybar.enable = true;

    programs.qt5ct.enable = true;

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        # sway-alttab
        swaylock # lockscreen
        dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
        kanshi # autorandr
        mako # notification daemon
        swaylock
        waybar # status bar
        wl-clipboard
        xwayland # for legacy apps
      ];
    };

    environment = {
      etc = {
        # Put config files in /etc. Note that you also can put these in ~/.config, but then you can't manage them with NixOS anymore!
        "sway/config".source = ./dotfiles/sway/config;
        "xdg/waybar/config".source = ./dotfiles/waybar/config;
        "xdg/waybar/style.css".source = ./dotfiles/waybar/style.css;
      };
    };

    # Here we put a shell script into path, which lets us start sway.service (after importing the environment of the login shell).
    environment.systemPackages = with pkgs; [
      brightnessctl
      polkit_gnome

      (
        pkgs.writeTextFile {
          name = "startsway";
          destination = "/bin/startsway";
          executable = true;
          text = ''
            #! ${pkgs.bash}/bin/bash

            # first import environment variables from the login manager
            systemctl --user import-environment
            # then start the service
            exec systemctl --user start sway.service
          '';
        }
      )
    ];

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
          ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
        '';
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # kanshi doesn't have an option to specifiy config file yet, so it looks
        # at .config/kanshi/config
        ExecStart = ''
          ${pkgs.kanshi}/bin/kanshi
        '';
        RestartSec = 5;
        Restart = "always";
      };
    };

    services.redshift = {
      # Redshift with wayland support isn't present in nixos-19.09 atm. You have to cherry-pick the commit from https://github.com/NixOS/nixpkgs/pull/68285 to do that.
      package = pkgs.redshift-wlr;
    };

    services.xserver.enable = true;
    services.xserver.displayManager.defaultSession = "sway";
    services.xserver.displayManager.sddm.enable = true;
    # TODO: apply sddm theme
    services.xserver.libinput.enable = true;
  };
}
