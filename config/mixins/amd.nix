{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [ zenmonitor ];

    # Enable zenpower
    boot.kernelModules = [ "zenpower" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    boot.blacklistedKernelModules = [ "k10temp" ];

    hardware.cpu.amd.updateMicrocode = true;
  };
}
