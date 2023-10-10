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

    # hardware.opengl = {
    #   extraPackages = with pkgs; [
    #     intel-media-driver # LIBVA_DRIVER_NAME=iHD
    #     vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
    #     vaapiVdpau
    #     libvdpau-va-gl
    #   ];
    #   extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiIntel ];
    # };

    hardware.cpu.intel.updateMicrocode = true;
  };
}
