{ config, pkgs, lib, ... }:

let cfg = config._custom.hardware.efi;
in {
  options._custom.hardware.efi = {
    enable = lib.mkEnableOption "setup system boot and efi";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      tmp.cleanOnBoot = true;
    };
  };
}
