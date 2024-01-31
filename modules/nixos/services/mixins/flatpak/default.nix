{ config, lib, ... }:

let cfg = config._custom.services.flatpak;
in {
  options._custom.services.flatpak = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    environment.sessionVariables = { XDG_DATA_DIRS = [ "/usr/share" ]; };
    xdg.portal.enable = true;
  };
}
