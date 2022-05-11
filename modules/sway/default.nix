{ config, pkgs, lib, ... }:

let
  theme = config._theme;
  # startsway = pkgs.writeTextFile {
  #   name = "startsway";
  #   destination = "/bin/startsway";
  #   executable = true;
  #   text = builtins.readFile ./scripts/startsway.sh;
  # };
  sway-run-or-raise = pkgs.writeShellScriptBin "sway-run-or-raise.sh"
    (builtins.readFile ./scripts/sway-run-or-raise.sh);
  sway-focus = pkgs.writeShellScriptBin "sway-focus.sh"
    (builtins.readFile ./scripts/sway-focus.sh);

  # bash script to let dbus know about important env variables and
  # propogate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme 'Dracula'
    '';
  };
in {
  config = {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = [ ]; # block rxvt
      extraOptions = [ "--debug" ];
    };

    environment = {
      systemPackages = with pkgs; [
        # startsway
        sway-run-or-raise
        sway-focus

        dbus-sway-environment
        configure-gtk
      ];

      sessionVariables = { NIXOS_OZONE_WL = "1"; };

      etc = {
        "sway/config".text = ''
          ${builtins.readFile ./dotfiles/config}
          ${builtins.readFile ./dotfiles/keybindings}

          #### SWAY theme ####
          #                         title-border         title-bg                title-text            indicator       window-border
          client.focused            ${theme.purple}      ${theme.purple}         ${theme.background}   ${theme.cyan}   ${theme.purple}
          client.unfocused          ${theme.selection}   ${theme.selection}    ${theme.foreground}   ${theme.cyan}   ${theme.selection}
          client.focused_inactive   ${theme.comment}     ${theme.comment}        ${theme.foreground}   ${theme.cyan}   ${theme.comment}
          client.urgent             ${theme.pink}        ${theme.pink}           ${theme.background}   ${theme.cyan}   ${theme.pink}
        '';
        "sway/borders".source = ./assets/borders;

        "scripts/import-gsettings.sh" = {
          source = ./scripts/import-gsettings.sh;
          mode = "0755";
        };

        "scripts/sway-lock.sh" = {
          source = ./scripts/sway-lock.sh;
          mode = "0755";
        };
        "scripts/sway-autostart.sh" = {
          source = ./scripts/sway-autostart.sh;
          mode = "0755";
        };
        "scripts/color-picker.sh" = {
          source = ./scripts/color-picker.sh;
          mode = "0755";
        };
        "scripts/takeshot.sh" = {
          source = ./scripts/takeshot.sh;
          mode = "0755";
        };
        "scripts/recorder.sh" = {
          source = ./scripts/recorder.sh;
          mode = "0755";
        };

        "scripts/projects/sway-dangerp.sh" = {
          source = ./scripts/sway-dangerp.sh;
          mode = "0755";
        };
        "scripts/projects/sway-tas.sh" = {
          source = ./scripts/sway-tas.sh;
          mode = "0755";
        };
      };
    };

    # services.xserver.displayManager = {
    #   session = [{
    #     name = "customsway";
    #     manage = "desktop";
    #     start = ''
    #       ${startsway}/bin/startsway &
    #       waitPID=$!
    #     '';
    #   }];
    # };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    # systemd.user.services.sway = {
    #   description = "Sway - Wayland window manager";
    #   documentation = [ "man:sway(5)" ];
    #   bindsTo = [ "graphical-session.target" ];
    #   wants = [ "graphical-session-pre.target" ];
    #   after = [ "graphical-session-pre.target" ];
    #   # We explicitly unset PATH here, as we want it to be set by
    #   # systemctl --user import-environment in startsway
    #   environment.PATH = lib.mkForce null;
    #   serviceConfig = {
    #     Type = "simple";
    #     ExecStart = ''
    #       ${pkgs.dbus}/bin/dbus-run-session sway
    #     '';
    #     Restart = "on-failure";
    #     RestartSec = 3;
    #     TimeoutStopSec = 10;
    #   };
    # };
  };
}
