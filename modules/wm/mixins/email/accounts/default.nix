{ config, pkgs, lib, ... }:

let
  cfg = config._custom.wm.email;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
in {
  imports = [ ./personal.nix ./work.nix ];

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      accounts.email.maildirBasePath = "${hmConfig.home.homeDirectory}/Mail";
    };
  };
}
