{ config, lib, ... }:

let cfg = config._custom.de.kde;
in {
  options._custom.de.kde.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
  };
}

