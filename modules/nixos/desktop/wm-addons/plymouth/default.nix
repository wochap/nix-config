{ config, pkgs, lib, ... }:

let cfg = config._custom.de.plymouth;
in {
  options._custom.de.plymouth.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      font = "${pkgs.iosevka}/share/fonts/truetype/Iosevka-Regular.ttf";
    };

    # required if you use luks
    boot.initrd.systemd.enable = true;

    # hide boot messages
    boot.kernelParams = [
      # silent boot
      "quiet"

      # stop systemd from printing its version number
      "udev.log_level=3"

      # suppress successful messages in initramfs
      "systemd.show_status=auto"

      # stop systemd from printing its version number (initramfs)
      "rd.udev.log_level=3"
    ];

    # hide not harmful ACPI BIOS errors (AE_ALREADY_EXISTS) before plymouth
    # additionally, you can't toggle with esc the logs
    # additionally, it introduces a minor visual glitch in greetd
    # more info: https://forum.zorin.com/t/acpi-bios-error-help-to-make-sense-of-this/22035/2
    # boot.consoleLogLevel = 3;
  };
}

