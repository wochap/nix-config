{ config, pkgs, lib, ... }:

{
  config = {
    # Enable fn keys on Keychron
    boot = {
      extraModprobeConfig = ''
        options hid_apple fnmode=0
      '';
      kernelParams = [
        "hid_apple.fnmode=0"
      ];
      kernelModules = [
        "hid-apple"
      ];
    };
  };
}
