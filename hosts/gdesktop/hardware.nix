{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  networking = {
    # enable wol 2C:F0:5D:73:55:AB
    interfaces.enp6s0.wakeOnLan.enable = true;
  };

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = true;

  # improve RAM usage
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      priority = 10;
    }
  ];

  nix.settings.system-features = [ "gccarch-znver4" ];
}
