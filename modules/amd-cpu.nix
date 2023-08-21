{ config, pkgs, lib, ... }:

let cfg = config._custom.amdCpu;
in {
  options._custom.amdCpu = { enable = lib.mkEnableOption "activate AMD CPU"; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ zenmonitor ];

    # Enable zenpower
    boot.kernelModules = [ "zenpower" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    boot.blacklistedKernelModules = [ "k10temp" ];

    hardware.cpu.amd.updateMicrocode = true;
  };
}
