{ config, pkgs, lib, ... }:

let
  # Get nixpkgs with nvidia 470.x
  customNixpkgs = import (builtins.fetchTarball {
    name = "nixpkgs-with-nvidia-x11-470.57.02";
    url = https://github.com/nixos/nixpkgs/archive/03100da5a714a2b6c5210ceb6af092073ba4fce5.tar.gz;
    sha256 = "0bblrvhig7vwiq2lgjrl5ibil3sz7hj26gaip6y8wpd9xcjr3v7a";
  }) { config.allowUnfree = true; };
  # We'll use this twice
  customKernelPackages = customNixpkgs.linuxPackages_latest;
in
{
  config = {
    # Install nvidia 470
    nixpkgs.config.packageOverrides = pkgs: {
      # Swap out all of the linux packages
      linuxPackages_latest = customKernelPackages;
      # Make sure x11 will use the correct package as well
      nvidia_x11 = customNixpkgs.nvidia_x11;
    };

    # Line up your kernel packages at boot
    boot.kernelPackages = customKernelPackages;
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
