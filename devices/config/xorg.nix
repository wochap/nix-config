{ config, pkgs, lib, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
  isHidpi = config._isHidpi;
in
{
  imports = [
    ./modules/lightdm-webkit2-greeter
    ./mixins/eww
    ./mixins/bspwm
    ./common.nix
  ];

  config = {
    _displayServer = "xorg";

    # Setup DE bspwm and sxhkdrc
    environment.etc = {
      "fix_caps_lock_delay.sh" = {
        source = ./scripts/fix_caps_lock_delay.sh;
        mode = "0755";
      };
    };
    services.xserver = {
      enable = true;
      exportConfiguration = true;
      desktopManager = {
        xterm.enable = false;
      };
      displayManager = {
        sddm = {
          enable = false;
          enableHidpi = false;
          theme = "sugar-dark";
          extraConfig = lib.mkIf isHidpi ''
            [X11]
            ServerArguments=-dpi 144
          '';
        };
        lightdm = {
          enable = true;
          background = ./assets/wallpaper.jpg;
          greeters.webkit2 = {
            enable = false;
            detectThemeErrors = false;
            debugMode = true;
            webkitTheme = pkgs.fetchzip {
              stripRoot = true;
              url = "https://github.com/wochap/lightdm-webkit2-theme-glorious/archive/7ce9c6c04a5676481fff03d585efa6c97bd40ad2.zip";
              sha256 = "0zl1fcbwfhlpjxn2zq50bffsvgkp49ch0k2djyhkbnih2fbqdykm";
            };
            branding = {
              userImage = ./assets/profile.jpg;
            };
          };
          greeters.gtk = {
            enable = true;
            cursorTheme.name = "capitaine-cursors";
            cursorTheme.package = pkgs.capitaine-cursors;
            cursorTheme.size = if isHidpi then 40 else 16;
            iconTheme.name = "WhiteSur-dark";
            iconTheme.package = localPkgs.whitesur-dark-icons;
            theme.name = "WhiteSur-dark";
            theme.package = localPkgs.whitesur-dark-theme;
            extraConfig = ''
              font-name=Roboto 9
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
    services.unclutter.enable = true;

    # Hide cursor when typing
    services.xbanish.enable = true;
    services.xbanish.arguments = "-i shift -i control -i super -i alt -i space";

    # Add wifi tray
    programs.nm-applet.enable = true;
  };
}
