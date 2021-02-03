{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  config = {
    # Setup DE bspwm and sxhkdrc
    environment = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        ELECTRON_TRASH="gvfs";
      };
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
          # background = ./wallpapers/default.jpeg;
          greeters.gtk.enable = true;
          greeters.gtk.cursorTheme.name = "Capitaine Cursors";
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
    services.picom = {
      enable = true;
      vSync = true;
    };
    # Hide cursor on typing
    services.xbanish.enable = true;
  };
}
