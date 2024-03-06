{ config, lib, ... }:

let cfg = config._custom.de.logind;
in {
  options._custom.de.logind.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.logind = {
      suspendKeyLongPress = "ignore";
      suspendKey = "ignore";
      rebootKeyLongPress = "ignore";
      rebootKey = "ignore";
      powerKeyLongPress = "ignore";
      powerKey = "ignore";
      hibernateKeyLongPress = "ignore";
      hibernateKey = "ignore";
      lidSwitchExternalPower = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitch = "suspend";
    };
  };
}
