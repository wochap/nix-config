{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.wayland-session;
  start-wm-dependencies = pkgs.writeScriptBin "start-wm-dependencies"
    (builtins.readFile ./scripts/start-wm-dependencies.sh);
in {
  options._custom.desktop.wayland-session.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.globals.displayServer = "wayland";

    environment.systemPackages = with pkgs; [ vulkan-validation-layers ];

    # Enable portal
    environment.sessionVariables.GTK_USE_PORTAL = "1";
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];

    programs.xwayland.enable = true;

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
      home.packages = [ start-wm-dependencies ];

      home.sessionVariables = {
        # Force GTK to use wayland
        GDK_BACKEND = "wayland,x11";
        CLUTTER_BACKEND = "wayland";

        # Force QT to use wayland
        QT_QPA_PLATFORM = "wayland;xcb";

        # Force firefox to use wayland
        MOZ_ENABLE_WAYLAND = "1";

        XDG_SESSION_TYPE = lib.mkDefault "wayland";
      };

      # fake a tray to let apps start
      # https://github.com/nix-community/home-manager/issues/2064
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      # starting this target will also start graphical-session targets
      # NOTE: update dbus and systemd env variables so that gtk apps start without delay
      systemd.user.targets.wayland-session = {
        Unit = {
          Description = "wayland compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    };
  };
}

