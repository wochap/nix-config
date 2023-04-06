{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/mixins/mbpfan";
in {
  config = {
    services.mbpfan.enable = lib.mkForce false;

    boot.kernelModules = [ "coretemp" "applesmc" ];
    environment = {
      systemPackages = with pkgs; [ mbpfan ];

      etc = {
        "scripts/mbpfan-polybar.sh" = {
          source = ./scripts/mbpfan-polybar.sh;
          mode = "0755";
        };
        "scripts/rofi-mbpfan.sh" = {
          source = ./scripts/rofi-mbpfan.sh;
          mode = "0755";
        };
        "scripts/wofi-mbpfan.sh" = {
          source = ./scripts/wofi-mbpfan.sh;
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

    # environment.etc."mbpfan.conf".source = ./dotfiles/mbpfan.conf;
    # environment.etc."mbpfan.conf".source =
    #   mkOutOfStoreSymlink "${configDirectory}/dotfiles/mbpfan.conf";
  };
}
