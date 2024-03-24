{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.udev-rules;

  cornekbd = pkgs.writeTextFile {
    name = "99-cornekbd.rules";
    text = ''
      ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="4653", ATTRS{id/product}=="0001", ATTRS{name}=="foostan Corne Keyboard", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="disable-glegion-builtin-kbd", ENV{SYSTEMD_ALIAS}="/sys/devices/cornekbd"
    '';
    destination = "/etc/udev/rules.d/99-cornekbd.rules";
  };
in {
  options._custom.desktop.udev-rules.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ cornekbd ];

    systemd.services.disable-glegion-builtin-kbd = {
      description = "Disable glegion builtin kbd when Corne kbd is connected";
      bindsTo = [ "sys-devices-cornekbd.device" ];
      serviceConfig = {
        ExecStart = "${pkgs.evtest}/bin/evtest --grab /dev/input/event17";
      };
    };
  };
}
