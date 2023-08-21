{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  localPkgs = import ../packages { inherit pkgs lib; };
in {
  config = {
    environment.systemPackages = with pkgs; [

      # required by https://github.com/sickcodes/Docker-OSX
      bison
      bridge-utils
      dnsmasq
      flex
      libvirt
      nftables
      qemu
      virt-manager
      xorg.xhost

      # required by iPhone USB -> Network style passthrough
      libusbmuxd
      localPkgs.usbfluxd
      socat
      usbmuxd
    ];

    # required by iPhone USB -> Network style passthrough
    services.avahi.enable = true;
    services.usbmuxd.enable = true;

    # this is needed to get a bridge with DHCP enabled
    virtualisation.libvirtd = {
      enable = true;

      qemu.ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull ];
      };
    };

    users.users.${userName}.extraGroups = [ "libvirtd" "kvm" ];

    boot.extraModprobeConfig = ''
      options kvm_amd nested=1

      options kvm ignore_msrs=1
    '';

    home-manager.users.${userName} = {
      # fix "could not detect a default hypervisor" in virt-manager
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };
  };
}
