{ config, pkgs, lib, ... }:

# NOTE: don't forget to install spice on guest
# https://www.spice-space.org/download.html
let cfg = config._custom.services.virt;
in {
  options._custom.services.virt.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spice-autorandr
      spice-vdagent

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
      # _custom.usbfluxd # build fails unstable
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

    _custom.user.extraGroups = [ "libvirtd" "kvm" ];

    boot.extraModprobeConfig = ''
      options kvm_amd nested=1

      options kvm ignore_msrs=1
    '';

    _custom.hm = {
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
