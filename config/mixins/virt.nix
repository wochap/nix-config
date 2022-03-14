{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [

      # required by https://github.com/sickcodes/Docker-OSX
      bison
      bridge-utils
      dnsmasq
      flex
      nftables
      qemu
      virt-manager
      xorg.xhost
    ];

    # this is needed to get a bridge with DHCP enabled
    virtualisation.libvirtd = {
      enable = true;

      qemu.ovmf = {
        enable = true;
        package = pkgs.OVMFFull;
      };
    };

    users.users.${userName}.extraGroups = [ "libvirtd" "kvm" ];

    boot.extraModprobeConfig = ''
      options kvm_amd nested=1

      options kvm ignore_msrs=1
    '';
  };
}
