{ inputs, lib, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-legion-16aph8
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  config = {
    hardware.amdgpu.amdvlk = true;
    hardware.amdgpu.loadInInitrd = true;

    services.thermald.enable = lib.mkDefault true;
    services.fwupd.enable = true;
  };
}
