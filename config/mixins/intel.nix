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

    services.xserver = {
      videoDrivers = [ "intel" ];

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };

    hardware.cpu.intel.updateMicrocode = true;
  };
}
