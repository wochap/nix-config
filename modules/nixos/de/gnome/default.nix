{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.gnome;
  extensionsPkgs = with pkgs.gnomeExtensions; [
    # appindicator
    # dash-to-panel
    blur-my-shell
    clipboard-indicator
    workspace-indicator
    just-perfection # customize GNOME Shell
  ];
in {
  options._custom.de.gnome.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.gnome.excludePackages = with pkgs; [ epiphany gnome-tour ];
    environment.systemPackages = with pkgs;
      [ gnome.gnome-tweaks ] ++ extensionsPkgs;

    # Required for app indicators
    services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

    services.gnome.games.enable = false;
    services.gnome.gnome-browser-connector.enable = true;
    services.xserver.displayManager.lightdm.enable = false;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    _custom.hm.dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions =
          (builtins.map (extension: extension.extensionUuid) extensionsPkgs);
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        switch-to-workspace-7 = [ "<Super>7" ];
        switch-to-workspace-8 = [ "<Super>8" ];
        switch-to-workspace-9 = [ "<Super>9" ];
        switch-to-workspace-10 = [ "<Super>0" ];

        move-to-workspace-1 = [ "<Shift><Super>1" ];
        move-to-workspace-2 = [ "<Shift><Super>2" ];
        move-to-workspace-3 = [ "<Shift><Super>3" ];
        move-to-workspace-4 = [ "<Shift><Super>4" ];
        move-to-workspace-5 = [ "<Shift><Super>5" ];
        move-to-workspace-6 = [ "<Shift><Super>6" ];
        move-to-workspace-7 = [ "<Shift><Super>7" ];
        move-to-workspace-8 = [ "<Shift><Super>8" ];
        move-to-workspace-9 = [ "<Shift><Super>9" ];
        move-to-workspace-10 = [ "<Shift><Super>0" ];
      };

      "org/gnome/shell/keybindings" = {
        # Remove the default hotkeys for opening favorited applications.
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
        switch-to-application-5 = [ ];
        switch-to-application-6 = [ ];
        switch-to-application-7 = [ ];
        switch-to-application-8 = [ ];
        switch-to-application-9 = [ ];
        switch-to-application-10 = [ ];
      };
    };
  };
}
