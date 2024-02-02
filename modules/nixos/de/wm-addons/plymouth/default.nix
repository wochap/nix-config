{ config, pkgs, lib, ... }:

let cfg = config._custom.wm.plymouth;
in {
  options._custom.wm.plymouth.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      font = "${pkgs.iosevka}/share/fonts/truetype/iosevka-regular.ttf";
    };

    # required if you use luks
    boot.initrd.systemd.enable = true;

    # hide boot messages
    boot.kernelParams = [ "quiet" "udev.log_level=3" ];
  };
}

