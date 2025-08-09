{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.wayland-session;
in {
  options._custom.desktop.wayland-session.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.globals.displayServer = "wayland";

    environment.systemPackages = with pkgs; [ vulkan-validation-layers ];

    # Enable portal
    environment.sessionVariables.GTK_USE_PORTAL = "1";
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      kdePackages.xdg-desktop-portal-kde
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
      home.sessionVariables = {
        # Force GTK to use wayland
        GDK_BACKEND = "wayland,x11,*";
        CLUTTER_BACKEND = "wayland";

        SDL_VIDEODRIVER = "wayland";

        # Force QT to use wayland
        QT_QPA_PLATFORM = "wayland;xcb";

        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

        # Force firefox to use wayland
        MOZ_ENABLE_WAYLAND = "1";

        XDG_SESSION_TYPE = lib.mkDefault "wayland";
      };

      # wayland.systemd.target = "graphical-session.target";

      # fake a tray to let apps start
      # https://github.com/nix-community/home-manager/issues/2064
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };
    };
  };
}

