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
    ];
    services.thermald.enable = lib.mkDefault true;
    services.fwupd.enable = true;
  };
}
