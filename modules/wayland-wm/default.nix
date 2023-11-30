{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  imports = [
    ./mixins/ags
    ./mixins/dunst
    ./mixins/swappy
    ./mixins/swaynotificationcenter
    ./mixins/swww
    ./mixins/system
    ./mixins/tofi
    ./mixins/waybar
    ./mixins/wob
    ./mixins/yambar
    ./mixins/gammastep.nix
    ./mixins/kanshi.nix
  ];

  options._custom.waylandWm = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _displayServer = "wayland";
    _custom.globals.displayServer = "wayland";

    nixpkgs.overlays = [
      (final: prev: {
        showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: {
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
      # inputs.xdg-portal-hyprland.packages.${pkgs.system}.default
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
    };
  };
}
