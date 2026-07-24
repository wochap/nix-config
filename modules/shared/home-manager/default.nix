{
  config,
  lib,
  options,
  inputs,
  pkgs,
  ...
}:

let
  inherit (config._custom.globals) userName homeDirectory;
  cfg = config._custom.home-manager;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options._custom = {
    home-manager.enable = lib.mkEnableOption { };

    hm = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Options to pass directly to home-manager primary user.";
    };

    user = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Options to pass directly to users.extraUsers primary user.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.user.home = homeDirectory;

    home-manager = {
      useGlobalPkgs = true;
      # Speed up home-manager service
      useUserPackages = true;
      backupFileExtension = "hm-bak";
    };

    _custom.hm = {
      imports = [
        ./symlinks
        ./copy-files
      ];

      config = {
        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
        programs.home-manager.package =
          inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default;

        # Home Manager needs a bit of information about you and the
        # paths it should manage.
        home.username = userName;
        home.homeDirectory = homeDirectory;
      };
    };

    # hm -> home-manager.users.<primary user>
    home-manager.users.${userName} = lib.mkAliasDefinitions options._custom.hm;

    # user -> users.extraUsers.<primary user>
    users.extraUsers.${userName} = lib.mkAliasDefinitions options._custom.user;
  };
}
