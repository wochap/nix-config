{ config, lib, options, ... }:

let inherit (config._custom.globals) userName;
in {
  options = {
    _custom.hm = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Options to pass directly to home-manager primary user.";
    };

    _custom.user = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Options to pass directly to users.extraUsers primary user.";
    };
  };

  config = {
    # hm -> home-manager.users.<primary user>
    home-manager.users.${userName} = lib.mkAliasDefinitions options._custom.hm;

    # user -> users.extraUsers.<primary user>
    users.extraUsers.${userName} = lib.mkAliasDefinitions options._custom.user;
  };
}
