{ config, pkgs, lib, ... }:

let
  samsungId = "04e8";
in
{
  config = {
    programs.adb.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${samsungId}", MODE="0666", GROUP="plugdev"
    '';
  };
}
