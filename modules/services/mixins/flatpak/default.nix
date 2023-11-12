{ config, pkgs, lib, ... }:

let
  cfg = config._custom.flatpak;
  userName = config._userName;
in {
  options._custom.flatpak = { enable = lib.mkEnableOption "enable flatpak"; };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    environment.sessionVariables = { XDG_DATA_DIRS = [ "/usr/share" ]; };
    xdg.portal.enable = true;
  };
}
