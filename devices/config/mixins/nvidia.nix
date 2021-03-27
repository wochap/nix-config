{ config, pkgs, lib, ... }:
let
  # Get the last working revision with nvidia 460.x
  nixos-unstable-pinned = import (builtins.fetchTarball {
    name = "nixos-unstable_nvidia-x11-460.56-5.11.7";
    url = https://github.com/nixos/nixpkgs/archive/a81a9d7425dea27d90028b731471b598f5553454.tar.gz;
    sha256 = "06jkpch2p2lgca0jf4zpryvlhwyyaprbfxyk3dlz60npahsfv2mf";
  }) { config.allowUnfree = true; };
  # We'll use this twice
  pinnedKernelPackages = nixos-unstable-pinned.linuxPackages_latest;
in
{
  config = {
    # Install nvidia 460
    nixpkgs.config.packageOverrides = pkgs: {
      # Swap out all of the linux packages
      linuxPackages_latest = pinnedKernelPackages;
      # Make sure x11 will use the correct package as well
      nvidia_x11 = nixos-unstable-pinned.nvidia_x11;
    };
    boot = {
      # Line up your kernel packages at boot
      kernelPackages = pinnedKernelPackages;
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
