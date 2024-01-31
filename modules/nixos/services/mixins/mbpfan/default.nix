{ config, pkgs, lib, ... }:

let cfg = config._custom.services.mbpfan;
in {
  options._custom.services.mbpfan = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    services.mbpfan.enable = lib.mkForce false;

    boot.kernelModules = [ "coretemp" "applesmc" ];
    environment = {
      systemPackages = with pkgs; [ mbpfan ];

      etc = {
        "scripts/mbpfan-bar.sh" = {
          source = ./scripts/mbpfan-bar.sh;
          mode = "0755";
        };
        "scripts/tofi-mbpfan.sh" = {
          source = ./scripts/tofi-mbpfan.sh;
          mode = "0755";
        };
      };
    };

    systemd.services.mbpfan = {
      description = "A fan manager daemon for MacBook Pro";
      wantedBy = [ "sysinit.target" ];
      after = [ "syslog.target" "sysinit.target" ];
      restartTriggers = [ "/etc/mbpfan.conf" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.mbpfan}/bin/mbpfan -fv";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        PIDFile = "/run/mbpfan.pid";
        Restart = "always";
      };
    };
  };
}
