{ config, pkgs, ... }:

let inherit (config._custom.globals) homeDirectory;
in {
  config = {
    environment.systemPackages = with pkgs; [
      chntpw # reset windows local account pwd
      _custom.pythonPackages.bt-dualboot # sync bt keys between windows and linux
    ];

    # Enable support for ntfs disks
    boot.supportedFilesystems = [ "ntfs" ];

    # Fix windows dualboot clock
    # on windows run:
    # $ reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
    # time.hardwareClockInLocalTime = true;

    # make Public folder accessible for windows
    services.samba = {
      enable = true;
      openFirewall = true;
      nsswins = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = config.networking.hostName;
          "netbios name" = config.networking.hostName;
          "security" = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        "public" = {
          path = "${homeDirectory}/Public";
          "public" = "yes";
          "read only" = "yes";
          "guest ok" = "yes";
        };
      };
    };

    # make shares visible for windows 10 clients
    services.samba-wsdd = {
      enable = true;
      workgroup = "WORKGROUP";
      openFirewall = true;
      hostname = config.networking.hostName;
    };
  };
}

