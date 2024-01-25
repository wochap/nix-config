{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  config = {
    hardware.amdgpu.amdvlk = true;
    hardware.amdgpu.loadInInitrd = true;
    hardware.amdgpu.opencl = true;

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    hardware.nvidia.prime = {
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };


    # Doesn't work yet...
    # boot.extraModulePackages = with config.boot.kernelPackages;
    #   [ lenovo-legion-module ];
    # NOTE: kernel 6.7.0 gives artifacts
    boot.kernelPackages = lib.mkForce pkgs.unstable.linuxPackages_6_6;

    boot.kernelParams = [
      # this doesn't fix my ACPI Bios errors :c
      # source: https://discordapp.com/channels/761178912230473768/1159412133117833286
      "acpi_osi=Linux"

      # Disables scatter/gather which was introduced with kernel version 6.2
      # It produces completely white or flashing screens when enabled while using the iGPU of Ryzen 7000-series CPUs (Raphael)
      "amdgpu.sg_display=0"
    ];

    environment.systemPackages = with pkgs; [
      lenovo-legion
      nvtop
      amdgpu_top
    ];
    environment.sessionVariables = {
      IGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:05:00.0-card)";
      DGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)";
      WLR_DRM_DEVICES = "$IGPU_CARD";
    };

    zramSwap.enable = true;

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    services.power-profiles-daemon.enable = lib.mkDefault true;

    services.thermald.enable = lib.mkDefault true;

    services.fwupd.enable = true;
  };
}
