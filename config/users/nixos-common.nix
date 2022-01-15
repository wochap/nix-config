{ config, pkgs, inputs, ... }:

let
  userName = config._userName;
  homeDirectory = "/home/${userName}";
in
{
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${userName} = {
      hashedPassword = "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
      home = homeDirectory;
      isNormalUser = true;
      extraGroups = [
        "audio"
        "disk"
        "docker"
        "networkmanager"
        "storage"
        "video"
        "wheel"
        "adbusers"
      ];

      # TODO: use keychain?
      openssh.authorizedKeys.keyFiles = [
        "~/.ssh/id_rsa.pub"
        "~/.ssh/id_rsa_boc.pub"
      ];
    };

    home-manager.users.${userName} = {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = userName;
      home.homeDirectory = homeDirectory;

      xresources.extraConfig = ''
        ${builtins.readFile "${inputs.dracula-xresources}/Xresources"}
      '';
    };
  };
}
