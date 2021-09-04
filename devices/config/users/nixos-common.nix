{ config, pkgs, ... }:

let
  userName = config._userName;
  homeDirectory = "/home/${userName}";
in
{
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${userName} = {
      password = "123456";
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
    };
  };
}
