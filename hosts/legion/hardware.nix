{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-legion-16aph8
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  config = {
    hardware.amdgpu.amdvlk = true;
    hardware.amdgpu.loadInInitrd = true;

    boot.extraModulePackages = with config.boot.kernelPackages;
      [ lenovo-legion-module ];

    environment.systemPackages = with pkgs; [
      lenovo-legion
      # nvtop
      amdgpu_top
    ];
    environment.sessionVariables = {
      IGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:05:00.0-card)";
      DGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)";
      WLR_DRM_DEVICES = "$IGPU_CARD:$DGPU_CARD";
    };

    # zramSwap.enable = true;

    services.thermald.enable = lib.mkDefault true;

    services.fwupd.enable = true;
  };
}
