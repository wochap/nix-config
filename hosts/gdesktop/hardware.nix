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

  config = {
    environment.systemPackages = with pkgs; [
      amdgpu_top
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
    ];

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    boot.kernelModules = [
      "msr" # cpu telemetry
      "k10temp" # ryzen 5900x
      "nct6775" # b550 motherboard
      "nvme"
      "drivetemp" # sata drive temp
      "hwmon_vid" # hw monitoring/power
    ];

    # enable ROCm
    boot.initrd.kernelModules = [ "amdgpu" ];

    networking = {
      # enable wol 2C:F0:5D:73:55:AB
      interfaces.enp6s0.wakeOnLan.enable = true;
    };

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    services.power-profiles-daemon.enable = true;

    # enable ROCm
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];

    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;

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
  };
}
