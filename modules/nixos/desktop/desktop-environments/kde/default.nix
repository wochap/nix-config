{ config, lib, ... }:

let cfg = config._custom.desktop.kde;
in {
  options._custom.desktop.kde.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.displayManager.sddm.wayland.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    # Fix home-manager activation
    # source: https://github.com/nix-community/home-manager/issues/3113
    programs.dconf.enable = true;
  };
}

