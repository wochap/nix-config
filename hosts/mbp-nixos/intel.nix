{ config, pkgs, lib, ... }:

{
  config = {
    boot = {
      # needed for powersave
      kernelParams = [
        "intel_pstate=active"

        # Intel i915 only
        # run `inxi -G` to verify
        "i915.enable_dpcd_backlight=1"
      ];
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
