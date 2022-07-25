{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.river;

  theme = config._theme;
  scripts = import ./scripts { inherit config pkgs lib; };
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
in {
  options._custom.river = { enable = lib.mkEnableOption "activate river"; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        river

        # scripts
        # TODO: add run-or-raise cli
        # TODO: add focus cli
        scripts.dbus-wayland-wm-environment
        scripts.configure-gtk
        scripts.lock-screen
      ];

      sessionVariables = {

        # enable wayland support (electron apps)
        NIXOS_OZONE_WL = "1";
      };

      etc = {
        "scripts/river-autostart.sh" = {
          source = ./scripts/river-autostart.sh;
          mode = "0755";
        };
        # "scripts/color-picker.sh" = {
        #   source = ./scripts/color-picker.sh;
        #   mode = "0755";
        # };
        # "scripts/takeshot.sh" = {
        #   source = ./scripts/takeshot.sh;
        #   mode = "0755";
        # };
        # "scripts/recorder.sh" = {
        #   source = ./scripts/recorder.sh;
        #   mode = "0755";
        # };

        # scripts to open projects blazingly fast
        # "scripts/projects/sway-dangerp.sh" = {
        #   source = ./scripts/sway-dangerp.sh;
        #   mode = "0755";
        # };
      };
    };

    home-manager.users.${userName} = {

      xdg.configFile = {

        "river/init" = {
          text = ''
            #!/bin/sh

            riverctl background-color 0x${unwrapHex theme.background}

            riverctl border-color-focused 0x${unwrapHex theme.purple}
            riverctl border-color-unfocused 0x${unwrapHex theme.selection}
            riverctl border-color-urgent 0x${unwrapHex theme.pink}

            ${builtins.readFile ./dotfiles/keybindings}
            ${builtins.readFile ./dotfiles/config}
          '';
          executable = true;
        };
      };
    };

  };
}
