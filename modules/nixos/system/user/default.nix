{ config, lib, ... }:

let
  inherit (config._custom.globals) configDirectory;
  cfg = config._custom.system.user;
in
{
  options._custom.system.user.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # create user
    _custom.user = {
      hashedPassword = "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
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

      xdg.configFile."secrets".source = lib._custom.mkOutOfStoreSymlink "${configDirectory}/secrets";
    };
  };
}
