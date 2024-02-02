{ config, lib, ... }:

let inherit (config._custom.globals) configDirectory;
in {
  config = {
    # create user
    _custom.user = {
      hashedPassword =
        "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
      isNormalUser = true;
      isSystemUser = false;
      extraGroups = [ "disk" "input" "storage" "video" ];
    };

    _custom.hm = {
      home.file = {
        "Projects/.keep".text = "";
        "Projects/wochap/.keep".text = "";
        "Picture/Screenshots/.keep".text = "";
        "Videos/Recordings/.keep".text = "";
      };

      xdg.configFile."secrets".source =
        lib._custom.mkOutOfStoreSymlink "${configDirectory}/secrets";
    };
  };
}
