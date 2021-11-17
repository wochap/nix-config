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
    ] ++ (if (isWayland) then [
      mesa-demos
      vulkan-tools
      glmark2
    ] else []);

    environment.variables = lib.mkIf isWayland {
      "WLR_NO_HARDWARE_CURSORS" = "1";
      "GBM_BACKENDS_PATH" = "/run/opengl-driver/lib/gbm";
      "GBM_BACKEND" = "nvidia-drm";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
      "OCL_ICD_VENDORS" = "/run/opengl-driver/etc/OpenCL/vendors";
    };

    services.xserver = {
      videoDrivers = [
        "nvidia"
      ];
    };
  };
}
