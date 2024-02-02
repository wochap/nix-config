{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  options._custom.waylandWm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.globals.displayServer = "wayland";

    nixpkgs.overlays = [
      (final: prev: {
        showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: {
          version = "6204cf1d4794578372c273348daa342589479b13";
          src = prev.fetchFromGitHub {
            owner = "AlynxZhou";
            repo = "showmethekey";
            rev = "6204cf1d4794578372c273348daa342589479b13";
            hash = "sha256-eeObomb4Gv/vpvViHsi3+O0JR/rYamrlZNZaXKL6KJw=";
          };
          buildInputs = oldAttrs.buildInputs ++ [ prev.libadwaita ];
        });
      })
    ];

    environment = {
      systemPackages = with pkgs; [
        wdisplays # control display outputs
        wlr-randr
        _custom.matcha
        showmethekey
        chayang # gradually dim the screen
        swaybg
      ];

      sessionVariables = {
        # enable wayland support (electron apps)
        NIXOS_OZONE_WL = "1";

        XDG_SESSION_TYPE = "wayland";

        # enable portal
        GTK_USE_PORTAL = "1";
      };
    };

    programs.xwayland.enable = true;

    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
    };

    # starting this target will also start graphical-session targets
    # NOTE: update dbus and systemd env variables so that gtk apps start without delay
    _custom.hm.systemd.user.targets.wayland-session = {
      Unit = {
        Description = "wayland compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    # HACK: allow manually start graphical-session-pre.target
    systemd.user.targets.graphical-session-pre.unitConfig = {
      RefuseManualStart = "no";
    };
    # HACK: allow manually start graphical-session.target
    systemd.user.targets.graphical-session.unitConfig = {
      RefuseManualStart = "no";
    };
  };
}

