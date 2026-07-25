{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.apparmor;
in
{
  options._custom.security.apparmor.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    security.apparmor.enable = true;
    services.dbus.apparmor = "enabled";
  };
}
