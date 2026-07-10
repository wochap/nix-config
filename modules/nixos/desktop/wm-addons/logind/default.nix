{ config, lib, ... }:

let cfg = config._custom.desktop.logind;
in {
  options._custom.desktop.logind = {
    enable = lib.mkEnableOption { };
    enableIgnoreLidSwitch = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    services.logind = {
      enable = true;
      settings.Login = {
        HandleSuspendKeyLongPress = "ignore";
        HandleSuspendKey = "ignore";
        HandleRebootKeyLongPress = "ignore";
        HandleRebootKey = "ignore";
        HandlePowerKeyLongPress = "poweroff";
        HandlePowerKey = "poweroff";
        HandleHibernateKeyLongPress = "ignore";
        HandleHibernateKey = "ignore";
        HandleLidSwitchExternalPower =
          if cfg.enableIgnoreLidSwitch then "ignore" else "suspend";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitch =
          if cfg.enableIgnoreLidSwitch then "ignore" else "suspend";
      };
    };
  };
}
