{ config, pkgs, lib, ... }:

let cfg = config._custom.de.xorg-session;
in {
  options._custom.de.xorg-session.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.globals.displayServer = "xorg";

    environment.systemPackages = with pkgs; [
      wmctrl # perform actions on windows
      wmutils-core # wm manipulation
      wmutils-opt # wm manipulation
      xautomation # simulate key press
      xdo # perform actions on windows
      xdotool # fake keyboard/mouse input
      xorg.xdpyinfo # show monitor info
      xorg.xeyes # check if app is running on wayland
      xorg.xinit # print window info
      xorg.xkbcomp # print keymap
      xorg.xrandr
      xorg.xwininfo # print window info
      xtitle
    ];

    # Enable portal
    # environment.sessionVariables.GTK_USE_PORTAL = "1";
    # xdg.portal.config.wlroots.default = [ "gtk" ];
    # xdg.portal.extraPortals = with pkgs; [
    #   xdg-desktop-portal-gtk
    # ];

    services.xserver.enable = true;

    # HACK: allow manually start graphical-session-pre.target
    systemd.user.targets.graphical-session-pre.unitConfig = {
      RefuseManualStart = "no";
    };
    # HACK: allow manually start graphical-session.target
    systemd.user.targets.graphical-session.unitConfig = {
      RefuseManualStart = "no";
    };

    _custom.hm = {
      # fake a tray to let apps start
      # https://github.com/nix-community/home-manager/issues/2064
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      # starting this target will also start graphical-session targets
      systemd.user.targets.xorg-session = {
        Unit = {
          Description = "xorg compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    };
  };
}

