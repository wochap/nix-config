{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    # this is needed to get a bridge with DHCP enabled
    virtualisation.libvirtd.enable = true;

    users.users.${userName}.extraGroups = [ "libvirtd" ];

    boot.extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_intel emulate_invalid_guest_state=0
      options kvm ignore_msrs=1
    '';
  };
}
