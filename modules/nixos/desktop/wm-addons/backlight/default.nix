{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.backlight;
in {
  options._custom.desktop.backlight.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        brightnessctl
        (writeScriptBin "backlight" (builtins.readFile ./scripts/backlight.sh))
        (writeScriptBin "kbd-backlight"
          (builtins.readFile ./scripts/kbd-backlight.sh))
      ];
    };

    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "90-amd-backlight.rules";
        text = ''
          ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
        '';
        destination = "/etc/udev/rules.d/90-amd-backlight.rules";
      })
    ];
  };
}
