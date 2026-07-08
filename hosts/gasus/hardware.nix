{ config, inputs, lib, pkgs, ... }:

{
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_16;

  # zramSwap.enable = true;

  networking = {
    # enable wol 54:A0:50:04:B1:69
    interfaces.enp2s0f1.wakeOnLan.enable = true;
  };
}

