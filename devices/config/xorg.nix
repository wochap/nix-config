{ config, pkgs, ... }:

let
  isDesktop = config.networking.hostName == "gdesktop";
in
{
  imports = [
    ./common.nix
  ];

  config = {
    _displayServer = "xorg";

    # Setup DE bspwm and sxhkdrc
    environment = {
      etc = {
        bspwmrc = {
          source = ./dotfiles/bspwmrc;
          mode = "0755";
        };
        sxhkdrc = {
          source = ./dotfiles/sxhkdrc;
          mode = "0755";
        };
        sxhkd-help = {
          source = ./scripts/sxhkd-help.sh;
          mode = "0755";
        };
      };
    };
    services.xserver = {
      enable = true;
      exportConfiguration = true;
      windowManager.bspwm = {
        enable = true;
        configFile = "/etc/bspwmrc";
        sxhkd.configFile = "/etc/sxhkdrc";
      };
      desktopManager.xterm.enable = false;
      displayManager = {
        defaultSession = "none+bspwm";
        lightdm = {
          enable = true;
          background = ./wallpapers/default.jpeg;
          greeters.gtk.enable = true;
          greeters.gtk.cursorTheme.name = "Capitaine Cursors"; #FIXME
          greeters.gtk.cursorTheme.package = pkgs.capitaine-cursors;
          greeters.gtk.iconTheme.name = "Arc";
          greeters.gtk.iconTheme.package = pkgs.arc-icon-theme;
          greeters.gtk.theme.name = "Arc-Dark";
          greeters.gtk.theme.package = pkgs.arc-theme;
          greeters.gtk.extraConfig = ''
            greeter-hide-users=false
          '';
        };
      };
    };

    services.picom = if isDesktop then {
      # Fix tearing on nvidia 1650 super
      enable = true;
      vSync = "opengl";
      backend = "xr_glx_hybrid";
    } else {
      enable = true;
      vSync = "opengl";
    };

    # Hide cursor automatically
    services.unclutter = {
      enable = true;
    };

    # Hide cursor when typing
    services.xbanish.enable = true;

    services.xserver.useGlamor = true;
  };
}
