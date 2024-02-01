{ ... }:

{
  config = {
    # create user
    _custom.user = {
      hashedPassword =
        "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
      isNormalUser = true;
      isSystemUser = false;
      extraGroups = [ "audio" "disk" "input" "storage" "video" ];
    };

    _custom.hm.home.file = {
      "Projects/.keep".text = "";
      "Projects/wochap/.keep".text = "";
      "Picture/Screenshots/.keep".text = "";
      "Videos/Recordings/.keep".text = "";
    };
  };
}
