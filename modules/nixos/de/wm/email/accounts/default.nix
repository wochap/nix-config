{ config, lib, ... }:

let
  cfg = config._custom.wm.email;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
in {
  imports = [ ./personal.nix ./work.nix ];

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      accounts.email.maildirBasePath = "${hmConfig.home.homeDirectory}/Mail";
    };
  };
}
