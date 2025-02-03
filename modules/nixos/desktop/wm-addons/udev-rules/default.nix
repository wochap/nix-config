{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.udev-rules;

  cornekbd = pkgs.writeTextFile {
    name = "99-cornekbd.rules";
    text = ''
      ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="4653", ATTRS{id/product}=="0001", ATTRS{name}=="foostan Corne Keyboard", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="cornekbd-disable-glegion-builtin-kbd", ENV{SYSTEMD_ALIAS}="/sys/devices/cornekbd"
    '';
    destination = "/etc/udev/rules.d/99-cornekbd.rules";
  };
  chocofikbd = pkgs.writeTextFile {
    name = "99-chocofikbd.rules";
    text = ''
      ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="1d50", ATTRS{id/product}=="615e", ATTRS{name}=="Chocochap Keyboard", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="chocofikbd-disable-glegion-builtin-kbd", ENV{SYSTEMD_ALIAS}="/sys/devices/chocofikbd"
    '';
    destination = "/etc/udev/rules.d/99-chocofikbd.rules";
  };
in {
  options._custom.desktop.udev-rules.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.udev.enable = true;
    services.udev.packages = [ cornekbd chocofikbd ];

    systemd.services.cornekbd-disable-glegion-builtin-kbd = {
      description = "Disable glegion builtin kbd when Corne kbd is connected";
      bindsTo = [ "sys-devices-cornekbd.device" ];
      serviceConfig = {
        ExecStart = "${pkgs.evtest}/bin/evtest --grab /dev/input/event17";
      };
    };

    systemd.services.chocofikbd-disable-glegion-builtin-kbd = {
      description = "Disable glegion builtin kbd when Chocofi kbd is connected";
      bindsTo = [ "sys-devices-chocofikbd.device" ];
      serviceConfig = {
        ExecStart = "${pkgs.evtest}/bin/evtest --grab /dev/input/event17";
      };
    };
  };
}
