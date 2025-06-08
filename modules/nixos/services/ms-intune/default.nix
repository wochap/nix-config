{ config, pkgs, lib, ... }:

let cfg = config._custom.services.ms-intune;
in {
  options._custom.services.ms-intune.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    users.users.microsoft-identity-broker = {
      group = "microsoft-identity-broker";
      isSystemUser = true;
    };

    users.groups.microsoft-identity-broker = { };
    environment.systemPackages = with pkgs; [
      prevstable-intune.microsoft-identity-broker
      prevstable-intune.intune-portal
    ];
    systemd.packages = with pkgs; [
      prevstable-intune.microsoft-identity-broker
      prevstable-intune.intune-portal
    ];

    systemd.tmpfiles.packages = with pkgs; [ prevstable-intune.intune-portal ];
    services.dbus.packages = with pkgs;
      [ prevstable-intune.microsoft-identity-broker ];
  };
}
