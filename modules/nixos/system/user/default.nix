{ config, lib, ... }:

let
  inherit (config._custom.globals) configDirectory;
  cfg = config._custom.system.user;
in
{
  options._custom.system.user = {
    enable = lib.mkEnableOption { };
    # generate password with `mkpasswd -m sha-512`
    password = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    # create user
    _custom.user = {
      hashedPassword = cfg.password;
      isNormalUser = true;
      isSystemUser = false;
      extraGroups = [
        "disk"
        "input"
        "storage"
        "video"
      ];
    };

    _custom.hm = {
      home.file = {
        "Projects/.keep".text = "";
        "Projects/wochap/.keep".text = "";
        "Pictures/Screenshots/.keep".text = "";
        "Videos/Recordings/.keep".text = "";
        "Videos/OBS/.keep".text = "";
      };
    };
  };
}
