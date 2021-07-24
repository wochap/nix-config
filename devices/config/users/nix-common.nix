{ config, pkgs, ... }:

{
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gean = {
      shell = pkgs.zsh;
      uid = 1000;
    };
  };
}
