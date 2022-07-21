{ config, pkgs, lib, ... }:

let cfg = config._custom.efi;
in {
  options._custom.efi = {
    enable = lib.mkEnableOption "setup system boot and efi";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };
  };
}
