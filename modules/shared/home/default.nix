{ config, lib, options, inputs, system, ... }:

let inherit (config._custom.globals) userName homeDirectory;
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
      description =
        "Options to pass directly to users.extraUsers primary user.";
    };
  };

  config = {
    _custom.user.home = homeDirectory;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = false;
    home-manager.backupFileExtension = "hm-bak";

    _custom.hm = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = userName;
      home.homeDirectory = homeDirectory;

      # TODO: programs.home-manager.enable should add this pkg
      home.packages = [ inputs.home-manager.packages.${system}.default ];

      programs.bash.enable = true;
    };

    # hm -> home-manager.users.<primary user>
    home-manager.users.${userName} = lib.mkAliasDefinitions options._custom.hm;

    # user -> users.extraUsers.<primary user>
    users.extraUsers.${userName} = lib.mkAliasDefinitions options._custom.user;
  };
}
