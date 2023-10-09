{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  imports = [
    ./mixins/ags
    ./mixins/dunst
    ./mixins/kanshi.nix
    ./mixins/rofi
    ./mixins/swaynotificationcenter
    ./mixins/swww
    ./mixins/system
    ./mixins/waybar
    ./mixins/wob
  ];

  options._custom.waylandWm = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    _displayServer = "wayland";
    _custom.globals.displayServer = "wayland";

    environment = {
      systemPackages = with pkgs; [
        wdisplays # control display outputs
        wlr-randr
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
      inputs.xdg-portal-hyprland.packages.${pkgs.system}.default
      xdg-desktop-portal-gtk
    ];

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
    };
  };
}
