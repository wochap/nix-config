{ config, pkgs, lib, ... }:

{
  config = {
    boot = {
      kernelParams = [
        "nouveau.modeset=0"
      ];
    };

    environment.systemPackages = with pkgs; [
      nvtop # monitor system nvidia
    ];

    services.xserver = {
      videoDrivers = [
        "nvidia"
      ];
    };
  };
}
