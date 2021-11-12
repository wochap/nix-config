{ config, pkgs, ... }:

let
  userName = config._userName;
in
{
  config = {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${userName} = {
      shell = pkgs.zsh;
      uid = 1000;
    };
  };
}
