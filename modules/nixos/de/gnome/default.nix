{ config, pkgs, lib, ... }:

let cfg = config._custom.gnome;
in {
  options._custom.gnome.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.gnome.excludePackages = with pkgs; [ epiphany ];

    environment.systemPackages = with pkgs; [
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.dash-to-panel
      # gnomeExtensions.tweaks-in-system-menu
      gnomeExtensions.workspace-indicator
      gnomeExtensions.x11-gestures
    ];

    services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    services.gnome.games.enable = false;
    services.gnome.gnome-browser-connector.enable = true;
    services.xserver.displayManager.lightdm.enable = false;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
  };
}
