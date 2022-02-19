{ config, pkgs, lib, ... }:

{
  config = {
    boot = {
      # needed for powersave
      kernelParams = [ "intel_pstate=active" ];
      kernelModules = [ "intel_pstate" ];
    };

    services.xserver.videoDrivers = [ "intel" ];

    hardware.cpu.intel.updateMicrocode = true;
  };
}
