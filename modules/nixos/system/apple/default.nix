{ config, pkgs, lib, ... }:

let cfg = config._custom.system.apple;
in {
  options._custom.system.apple = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # required by iPhone USB -> Network style passthrough
      # in qemu hackintosh
      libusbmuxd
      usbmuxd
      # _custom.usbfluxd # build fails unstable
    ];

    # enables communication with apple mobile devices
    services.usbmuxd.enable = true;
  };
}

