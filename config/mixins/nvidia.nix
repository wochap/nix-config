{ config, pkgs, lib, ... }:

{
  config = {
    hardware.nvidia.modesetting.enable = true;

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
