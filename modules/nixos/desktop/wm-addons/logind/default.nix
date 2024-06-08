{ config, lib, ... }:

let cfg = config._custom.desktop.logind;
in {
  options._custom.desktop.logind.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.logind = {
      suspendKeyLongPress = "ignore";
      suspendKey = "ignore";
      rebootKeyLongPress = "ignore";
      rebootKey = "ignore";
      powerKeyLongPress = "poweroff";
      powerKey = "poweroff";
      hibernateKeyLongPress = "ignore";
      hibernateKey = "ignore";
      lidSwitchExternalPower = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitch = "suspend";
    };
  };
}
