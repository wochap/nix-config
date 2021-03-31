{ config, pkgs, lib, ... }:

{
  config = {
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
