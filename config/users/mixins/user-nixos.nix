{ config, pkgs, inputs, ... }:

let
  userName = config._userName;
in
{
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${userName} = {
      hashedPassword = "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
      isNormalUser = true;
      isSystemUser = false;
      extraGroups = [
        "audio"
        "disk"
        "input"
        "networkmanager"
        "storage"
        "video"
        "wheel"
      ];
    };
  };
}

