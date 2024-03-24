{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.kanshi;
in {
  options._custom.desktop.kanshi.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ kanshi ]; };

    _custom.hm = {
      services.kanshi = {
        enable = true;
        systemdTarget = "wayland-session.target";
        extraConfig = ''
          profile docked-glegion {
            output "Samsung Display Corp. 0x4188" disable
            output "Goldstar Company Ltd LG ULTRAGEAR 112NTLEL9832" mode 3440x1440@99.990Hz scale 1
          }

          profile undocked-glegion {
            output "Samsung Display Corp." scale 2
          }
        '';
      };
    };
  };
}
