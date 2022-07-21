{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.river;

  theme = config._theme;
  scripts = import ./scripts { inherit config pkgs lib; };
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
        # "sway/config".text = ''
        #   ${builtins.readFile ./dotfiles/config}
        #   ${builtins.readFile ./dotfiles/keybindings}
        #
        #   #### SWAY theme ####
        #   #                         title-border         title-bg                title-text            indicator       window-border
        #   client.focused            ${theme.purple}      ${theme.purple}         ${theme.background}   ${theme.cyan}   ${theme.purple}
        #   client.unfocused          ${theme.selection}   ${theme.selection}    ${theme.foreground}   ${theme.cyan}   ${theme.selection}
        #   client.focused_inactive   ${theme.comment}     ${theme.comment}        ${theme.foreground}   ${theme.cyan}   ${theme.comment}
        #   client.urgent             ${theme.pink}        ${theme.pink}           ${theme.background}   ${theme.cyan}   ${theme.pink}
        # '';
        # "sway/borders".source = ./assets/borders;

        # "scripts/import-gsettings.sh" = {
        #   source = ./scripts/import-gsettings.sh;
        #   mode = "0755";
        # };

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

    home-manager.users.${userName} = {
      xdg.configFile = { "river/init".source = ./scripts/init; };
    };

  };
}
