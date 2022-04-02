{ config, pkgs, lib, ... }:

{
  config = {
    boot = {
      # needed for powersave
      kernelParams = [ "intel_pstate=active" ];
      kernelModules = [
        "intel_pstate"

        # required by lm_sensors
        "coretemp"
      ];
    };

    services.xserver.videoDrivers = [ "intel" ];

    hardware.cpu.intel.updateMicrocode = true;
  };
}
