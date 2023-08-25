{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
in {
  imports = [
    ./personal.nix
    ./work.nix
  ];

  config = {
    home-manager.users.${userName} = {
      accounts.email.maildirBasePath = "${hmConfig.home.homeDirectory}/Mail";
    };
  };
}
