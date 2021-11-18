{ config, pkgs, lib, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    hardware.nvidia.modesetting.enable = true;

    environment.systemPackages = with pkgs; [
      nvtop # monitor system nvidia

      # Tools to test HA
      mesa-demos
      vulkan-tools
      glmark2
    ];

    environment.variables = lib.mkMerge [
      {
        "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
        "OCL_ICD_VENDORS" = "/run/opengl-driver/etc/OpenCL/vendors";
      }
      (lib.mkIf isWayland {
        "WLR_NO_HARDWARE_CURSORS" = "1";
        "GBM_BACKENDS_PATH" = "/run/opengl-driver/lib/gbm";
        "GBM_BACKEND" = "nvidia-drm";
      })
    ];

    services.xserver = {
      videoDrivers = [
        "nvidia"
      ];
    };
  };
}
