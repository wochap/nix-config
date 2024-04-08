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
          profile glegion-docked {
            output "Samsung Display Corp. 0x4188 Unknown" disable
            output "Goldstar Company Ltd LG ULTRAGEAR 112NTLEL9832" mode 3440x1440@99.990Hz scale 1
          }

          profile glegion-undocked {
            output "Samsung Display Corp. 0x4188 Unknown" scale 2
          }

          profile stream-glegion {
            output "Samsung Display Corp. 0x4188 Unknown" scale 2
            output HEADLESS-1 {
              scale 2
              position 1440,0
              mode --custom 2880x1800@120Hz
            }
          }
        '';
      };
    };
  };
}
