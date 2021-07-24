{ config, pkgs, lib, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
  isHidpi = config._isHidpi;
in
{
  imports = [
    ./mixins/bspwm
    ./mixins/pkgs-xorg.nix
    ./mixins/nix-common.nix
    ./mixins/nixos.nix
    ./mixins/overlays.nix
    ./mixins/pkgs.nix
    ./mixins/fonts.nix
    ./mixins/ipwebcam
    ./mixins/nixos-networking.nix
    ./mixins/keychron.nix
    ./mixins/default-browser
    ./mixins/apps-gnome # Comment on first install
    ./mixins/apps-kde # Comment on first install
    ./mixins/apps-xfce.nix # Comment on first install
    ./mixins/docker.nix # Comment on first install
    ./mixins/lorri.nix
    ./mixins/vscode.nix
    ./users/gean.nix
  ];

  config = {
    _displayServer = "xorg";

    environment = {
      sessionVariables = {
        # Setup clipboard manager (clipmenu)
        CM_MAX_CLIPS = "30";
        CM_OWN_CLIPBOARD = "1";
        CM_SELECTIONS = "clipboard";
      };
      etc = {
        "scripts/fix_caps_lock_delay.sh" = {
          source = ./scripts/fix_caps_lock_delay.sh;
          mode = "0755";
        };

        # Install script for screenshoot
        "scripts/scrcap.sh" = {
          source = ./scripts/scrcap.sh;
          mode = "0755";
        };

        # Install script for recording
        "scripts/scrrec.sh" = {
          source = ./scripts/scrrec.sh;
          mode = "0755";
        };
      };
    };
    services.xserver = {
      enable = true;
      exportConfiguration = true;
      desktopManager = {
        xterm.enable = false;
      };

      # Setup login screen
      displayManager = {
        lightdm = {
          enable = true;
          background = ./assets/wallpaper.jpeg;
          greeters.gtk = {
            enable = true;
            cursorTheme.name = "bigsur-cursors";
            cursorTheme.package = localPkgs.bigsur-cursors;
            cursorTheme.size = if isHidpi then 40 else 16;
            iconTheme.name = "WhiteSur-dark";
            iconTheme.package = localPkgs.whitesur-dark-icons;
            theme.name = "WhiteSur-dark";
            theme.package = localPkgs.whitesur-dark-theme;
            extraConfig = ''
              font-name=Inter 9
            '';
            indicators = [
              "~host"
              "~spacer"
              "~clock"
              "~spacer"
              "~session"
              "~language"
              "~a11y"
              "~power"
            ];
          };
        };
      };
    };

    # Hide cursor automatically
    # services.unclutter.enable = true;

    # Hide cursor when typing
    services.xbanish.enable = true;
    services.xbanish.arguments = "-i shift -i control -i super -i alt -i space";

    # Add wifi tray
    programs.nm-applet.enable = true;
  };
}
